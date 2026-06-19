import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const BUCKET_USER_DOCUMENTS = "user_documents";
const SIGNED_URL_EXPIRY_SEC = 60 * 60; // 1 hour

function generateRandomPassword(): string {
  const chars = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%";
  let s = "";
  for (let i = 0; i < 14; i++) s += chars[Math.floor(Math.random() * chars.length)];
  return s;
}

/** Treat only real booleans / explicit strings as true (avoids JS treating any non-empty string as true). */
function truthyFlag(v: unknown): boolean {
  if (v === true || v === 1) return true;
  if (typeof v === "string") {
    const s = v.trim().toLowerCase();
    return s === "true" || s === "1" || s === "yes";
  }
  return false;
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
      throw new Error("Server misconfiguration: missing Supabase env.");
    }

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

    // Admin client (service_role)
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // Authorization model: profile flag only.
    const { data: profileEntry } = await adminClient
      .from("profiles")
      .select("is_admin")
      .eq("id", user.id)
      .single();

    const isAdmin = profileEntry?.is_admin === true;

    if (!isAdmin) {
      return new Response(JSON.stringify({ error: "Forbidden: administrative access required" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const { action, target_id, params } = body;

    let result: any = {};

    switch (action) {
      case "approve_driver":
      case "approve_company": {
        // SECURITY FIX V-03: Respect Workflow State Machine
        const entityType = action === "approve_driver" ? "driver" : "company";

        // We call a DB RPC or use the adminClient to advance verification
        // This ensures dual-approval and fraud checks are not bypassed.
        result = { success: true, message: "Action accepted but must be finalized via Verification Center for integrity." };
        break;
      }

      case "suspend_user": {
        // Use caller-auth context for profile governance writes so DB trigger
        // checks based on auth.uid() (is_admin/protect_profile_metadata)
        // evaluate against the acting admin user rather than service-role null.
        const { error } = await userClient
          .from("profiles")
          .update({ is_suspended: true, internal_notes: params?.reason })
          .eq("id", target_id);
        if (error) throw error;
        result = { success: true };
        break;
      }

      case "grant_role": {
        const { error } = await adminClient.from("user_roles").insert({
          user_id: target_id,
          role: params?.role,
          granted_by: user.id,
        });
        if (error) throw error;
        result = { success: true };
        break;
      }

      case "block_user": {
        // Hard-block: flips profiles.is_blocked AND bans the auth user.
        // Both writes are best-effort; if the auth ban fails the profile flag
        // still wins for in-app gating, but we surface the failure to the
        // caller so they can retry.
        const blocked: boolean = params?.blocked === true;
        const reason: string | undefined = params?.reason;

        // IMPORTANT: write governance fields through userClient (JWT context).
        // Using service_role here causes auth.uid() to be null inside trigger
        // checks and can reject updates with 400.
        const { error: profileError } = await userClient
          .from("profiles")
          .update({
            is_blocked: blocked,
            blocked_reason: blocked ? (reason ?? null) : null,
            blocked_at: blocked ? new Date().toISOString() : null,
            blocked_by: blocked ? user.id : null,
          })
          .eq("id", target_id);
        if (profileError) throw profileError;

        let authBanError: string | null = null;
        try {
          await adminClient.auth.admin.updateUserById(target_id, {
            ban_duration: blocked ? "876000h" : "none", // ~100y vs lift
          });
        } catch (e: any) {
          authBanError = e?.message ?? String(e);
          console.warn("[admin-action:block_user] auth ban failed:", authBanError);
        }

        result = { success: true, authBanError };
        break;
      }

      case "create_user": {
        // Provisions a new auth.users entry + profiles row. The
        // `admin_provision_profile` SQL function (00042) is service_role-only
        // and handles the profile upsert atomically once we have the user id.
        const p = params ?? {};
        if (!p.email && !p.phone) throw new Error("Either email or phone is required.");
        if (!p.full_name) throw new Error("full_name is required.");
        const isCompanyAccount = (p.account_type ?? "individual") === "company";
        const shouldMakeDriver = truthyFlag(p.make_driver);
        const shouldMakeCompany = isCompanyAccount || truthyFlag(p.make_company);

        let createdUserId: string | undefined;
        let generatedPassword: string | null = null;

        if (p.send_invitation && p.email) {
          const { data, error } = await adminClient.auth.admin.inviteUserByEmail(p.email, {
            data: { full_name: p.full_name },
          });
          if (error) throw error;
          createdUserId = data.user?.id;
        } else {
          const password: string = (p.password && p.password.length >= 6)
            ? p.password
            : generateRandomPassword();
          generatedPassword = p.password ? null : password;

          const { data, error } = await adminClient.auth.admin.createUser({
            email: p.email,
            phone: p.phone,
            password,
            email_confirm: !!p.email,
            phone_confirm: !!p.phone,
            user_metadata: { full_name: p.full_name },
          });
          if (error) throw error;
          createdUserId = data.user?.id;
        }

        if (!createdUserId) throw new Error("Auth user creation returned no id");

        // Upsert profile via the privileged SQL function (service_role-only).
        const { error: provError } = await adminClient.rpc("admin_provision_profile", {
          p_user_id: createdUserId,
          p_full_name: p.full_name,
          p_phone: p.phone ?? null,
          p_account_type: p.account_type ?? "individual",
          p_make_driver: shouldMakeDriver,
          p_make_company: shouldMakeCompany,
        });
        if (provError) {
          // Best-effort rollback: if profile provisioning fails, delete the
          // auth user to avoid orphan rows.
          try {
            await adminClient.auth.admin.deleteUser(createdUserId);
          } catch (rollbackErr) {
            console.error("[admin-action:create_user] rollback failed:", rollbackErr);
          }
          throw provError;
        }

        // Ensure role/status flags are applied even if a profile row already
        // existed and the RPC resolved via ON CONFLICT DO UPDATE path.
        const statusPatch: Record<string, string | boolean> = {};
        if (shouldMakeDriver) {
          statusPatch.traveler_status = "pending";
          statusPatch.is_driver = true;
          statusPatch.traveler_type = "with_vehicle";
        }
        if (shouldMakeCompany) statusPatch.company_status = "pending";
        if (Object.keys(statusPatch).length > 0) {
          const { error: statusError } = await adminClient
            .from("profiles")
            .update(statusPatch)
            .eq("id", createdUserId);
          if (statusError) throw statusError;
        }

        // Give newly-created company accounts a display name by default.
        if (isCompanyAccount) {
          const { error: companyNameError } = await adminClient
            .from("profiles")
            .update({ company_name: p.full_name })
            .eq("id", createdUserId)
            .is("company_name", null);
          if (companyNameError) throw companyNameError;
        }

        result = { success: true, userId: createdUserId, generatedPassword };
        break;
      }

      default:
        return new Response(JSON.stringify({ error: `Action '${action}' not supported in hardened mode or invalid.` }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    }

    // Audit is now handled by DB Triggers (Autonomous Auditing V2)
    // We don't need manual inserts here, avoiding double logging and stealth risks.

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: err.message.includes("Forbidden") ? 403 : 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
