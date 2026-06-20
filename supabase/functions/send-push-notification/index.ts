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
    const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");
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

    // Check admin role
    const { data: roles } = await adminClient
      .from("user_roles")
      .select("role")
      .eq("user_id", user.id);
    const userRoles = (roles || []).map((r: { role: string }) => r.role);
    const hasAdminAccess = userRoles.some((r: string) => ["super_admin", "admin", "moderator"].includes(r));

    if (!hasAdminAccess) {
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

    // 3. Send FCM push notifications
    let fcmSent = 0;
    let fcmFailed = 0;

    if (fcmServerKey) {
      // Get all FCM tokens for target users (batch query in chunks of 1000)
      const allTokens: string[] = [];
      for (let i = 0; i < targetUserIds.length; i += 1000) {
        const chunk = targetUserIds.slice(i, i + 1000);
        const { data: tokens } = await adminClient
          .from("notification_tokens")
          .select("token")
          .in("user_id", chunk);
        const chunkTokens = (tokens || []).map((t: { token: string }) => t.token).filter(Boolean);
        allTokens.push(...chunkTokens);
      }

      // Send in batches of 500 (FCM multicast limit)
      for (let i = 0; i < allTokens.length; i += 500) {
        const batch = allTokens.slice(i, i + 500);
        try {
          const fcmResponse = await fetch("https://fcm.googleapis.com/fcm/send", {
            method: "POST",
            headers: {
              Authorization: `key=${fcmServerKey}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              registration_ids: batch,
              notification: { title, body },
              data: notifData,
            }),
          });
          const fcmResult = await fcmResponse.json();
          fcmSent += fcmResult.success || 0;
          fcmFailed += fcmResult.failure || 0;
        } catch (e) {
          fcmFailed += batch.length;
        }
      }
    }

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
        fcm_sent: fcmSent,
        fcm_failed: fcmFailed,
      },
    });

    return new Response(
      JSON.stringify({
        success: true,
        in_app_sent: targetUserIds.length,
        fcm_sent: fcmSent,
        fcm_failed: fcmFailed,
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
