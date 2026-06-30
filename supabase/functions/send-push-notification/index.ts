import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface PushPayload {
  type: "broadcast" | "segment" | "user";
  title: string;
  body: string;
  data?: Record<string, string>;
  target_user_id?: string;
  segment_filter?: { role?: string };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!supabaseUrl || !serviceRoleKey || !anonKey) {
      return new Response(JSON.stringify({ error: "Server misconfiguration: missing Supabase env." }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify caller is admin
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // Authorize: admin only. The single `profiles.is_admin` flag is the security
    // boundary (the old role-tier `user_roles` table is vestigial).
    const { data: profile } = await adminClient
      .from("profiles")
      .select("is_admin")
      .eq("id", user.id)
      .single();
    if (!profile?.is_admin) {
      return new Response(JSON.stringify({ error: "Forbidden" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const payload: PushPayload = await req.json();
    const { type, title, body, data, target_user_id, segment_filter } = payload;

    if (!title || !body || !type) {
      return new Response(JSON.stringify({ error: "Missing title, body, or type" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Determine target user IDs
    let targetUserIds: string[] = [];

    if (type === "user") {
      if (!target_user_id) {
        return new Response(JSON.stringify({ error: "Missing target_user_id" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      targetUserIds = [target_user_id];
    } else if (type === "segment") {
      let query = adminClient.from("profiles").select("id");
      if (segment_filter?.role === "drivers") {
        query = query.not("traveler_status", "is", null).neq("traveler_status", "none");
      } else if (segment_filter?.role === "clients") {
        query = query.or("traveler_status.is.null,traveler_status.eq.none");
      }
      const { data: users } = await query;
      targetUserIds = (users || []).map((u: { id: string }) => u.id);
    } else {
      // broadcast
      const { data: users } = await adminClient.from("profiles").select("id");
      targetUserIds = (users || []).map((u: { id: string }) => u.id);
    }

    if (targetUserIds.length === 0) {
      return new Response(JSON.stringify({ sent: 0, message: "No target users found" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Insert in-app notifications (batch 500)
    const notifData = { type: "admin_push", ...data };
    const batchSize = 500;
    for (let i = 0; i < targetUserIds.length; i += batchSize) {
      const batch = targetUserIds.slice(i, i + batchSize).map((uid) => ({
        user_id: uid,
        title,
        body,
        data: notifData,
        is_read: false,
      }));
      await adminClient.from("notifications").insert(batch);
    }

    // 3. Push delivery
    // FCM push is dispatched asynchronously by the `notifications` INSERT trigger
    // (handle_new_notification), which calls the FCM v1 `push-notification` function
    // for each row inserted above. No direct FCM send here — the legacy
    // `fcm.googleapis.com/fcm/send` endpoint was decommissioned by Google in 2024.

    // 4. Audit log
    await adminClient.from("admin_audit_log").insert({
      admin_id: user.id,
      action: `push_notification_${type}`,
      target_type: "notification",
      target_id: target_user_id || null,
      details: {
        title,
        body,
        type,
        target_count: targetUserIds.length,
      },
    });

    return new Response(
      JSON.stringify({
        success: true,
        in_app_sent: targetUserIds.length,
        push_dispatch: "trigger",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : "Internal server error";
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
