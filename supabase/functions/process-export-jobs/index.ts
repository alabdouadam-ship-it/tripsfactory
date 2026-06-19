import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * process-export-jobs
 *
 * Polls the `export_jobs` table for rows with status='queued', generates a
 * CSV from the requested table + filter_config, uploads it to the
 * `admin_exports` storage bucket (private) under `{admin_id}/{job_id}.csv`,
 * mints a 24h signed URL, and marks the row as completed.
 *
 * Designed to be invoked on a schedule (every 1-5 minutes via Supabase
 * Dashboard → Edge Functions → Schedule, or via pg_cron + pg_net) but is
 * also safe to call ad-hoc by an admin to flush their own queue.
 *
 * Idempotency: each job is "claimed" by atomically flipping
 * status='queued' → 'processing' before work starts. Concurrent invocations
 * won't double-process the same job. If a job stays in 'processing' for
 * more than ~10 min, it's likely a crashed run; the next invocation can
 * recover by including stale 'processing' rows in the claim query (left as
 * a future enhancement; for now we only claim 'queued').
 */

const BUCKET_ADMIN_EXPORTS = "admin_exports";
const SIGNED_URL_EXPIRY_SEC = 24 * 60 * 60; // 24h
const BATCH_PAGE_SIZE = 1000; // PostgREST max rows per query
const MAX_ROWS_PER_JOB = 100_000; // safety cap to avoid runaway exports
const MAX_JOBS_PER_INVOCATION = 10; // process up to N queued jobs per call

// Whitelist of tables that can be exported. Keeps the Edge Function from
// being weaponized to dump arbitrary tables. Add to this list as new
// admin export buttons are wired up.
const ALLOWED_TABLES = new Set([
  "profiles",
  "trips",
  "shipments",
  "bookings",
  "ratings",
  "reports",
  "vehicles",
  "user_restrictions",
  "verification_workflow",
  "admin_audit_log",
  "audit_logs_v2",
  "locations",
  "blacklist_identifiers",
  "fraud_signals",
]);

// Allowed PostgREST filter operators
type FilterOp =
  | "eq" | "neq" | "gt" | "gte" | "lt" | "lte"
  | "like" | "ilike" | "in" | "is" | "not.is";

interface FilterClause {
  field: string;
  op: FilterOp;
  value: unknown;
}

interface ExportJob {
  id: string;
  admin_id: string;
  table_name: string;
  filter_config: FilterClause[] | null;
  status: string;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function requireEnv(name: string): string {
  const v = Deno.env.get(name);
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

/** Flatten one-level nested objects: { profile: { name: 'X' } } → { 'profile.name': 'X' } */
function flattenRow(row: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(row)) {
    if (v !== null && typeof v === "object" && !Array.isArray(v)) {
      for (const [k2, v2] of Object.entries(v as Record<string, unknown>)) {
        out[`${k}.${k2}`] = v2;
      }
    } else {
      out[k] = v;
    }
  }
  return out;
}

/** RFC 4180-compatible CSV cell escaping. */
function csvEscape(value: unknown): string {
  if (value === null || value === undefined) return "";
  const s = typeof value === "string" ? value : JSON.stringify(value);
  if (s.includes('"') || s.includes(",") || s.includes("\n") || s.includes("\r")) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

/** Convert array of row objects to a CSV string. */
function rowsToCSV(rows: Record<string, unknown>[]): string {
  if (rows.length === 0) return "";
  const flattened = rows.map(flattenRow);
  // Union all keys across rows so optional fields aren't dropped
  const keys = Array.from(
    flattened.reduce((set, r) => {
      Object.keys(r).forEach((k) => set.add(k));
      return set;
    }, new Set<string>()),
  );

  const lines: string[] = [];
  lines.push(keys.map(csvEscape).join(","));
  for (const row of flattened) {
    lines.push(keys.map((k) => csvEscape(row[k])).join(","));
  }
  return lines.join("\n");
}

/** Apply a filter clause to a PostgREST query builder. */
// deno-lint-ignore no-explicit-any
function applyFilter(query: any, clause: FilterClause): any {
  const { field, op, value } = clause;
  switch (op) {
    case "eq":  return query.eq(field, value);
    case "neq": return query.neq(field, value);
    case "gt":  return query.gt(field, value);
    case "gte": return query.gte(field, value);
    case "lt":  return query.lt(field, value);
    case "lte": return query.lte(field, value);
    case "like":  return query.like(field, value as string);
    case "ilike": return query.ilike(field, value as string);
    case "in":  return query.in(field, value as unknown[]);
    case "is":  return query.is(field, value);
    case "not.is": return query.not(field, "is", value);
    default:
      throw new Error(`Unsupported filter op: ${op}`);
  }
}

/** Fetch all rows for a job, paginated, with safety cap. */
async function fetchJobRows(
  admin: SupabaseClient,
  job: ExportJob,
): Promise<Record<string, unknown>[]> {
  if (!ALLOWED_TABLES.has(job.table_name)) {
    throw new Error(
      `Table '${job.table_name}' is not in the export whitelist. Add it to ALLOWED_TABLES if intentional.`,
    );
  }

  const all: Record<string, unknown>[] = [];
  let offset = 0;

  while (offset < MAX_ROWS_PER_JOB) {
    let query = admin
      .from(job.table_name)
      .select("*")
      .range(offset, offset + BATCH_PAGE_SIZE - 1);

    if (job.filter_config && Array.isArray(job.filter_config)) {
      for (const clause of job.filter_config) {
        if (!clause || !clause.field || !clause.op) continue;
        query = applyFilter(query, clause);
      }
    }

    const { data, error } = await query;
    if (error) throw error;
    if (!data || data.length === 0) break;

    all.push(...(data as Record<string, unknown>[]));
    if (data.length < BATCH_PAGE_SIZE) break;
    offset += BATCH_PAGE_SIZE;
  }

  return all;
}

/** Process a single export job end-to-end. Returns the updated row. */
async function processJob(admin: SupabaseClient, job: ExportJob): Promise<{
  ok: boolean;
  recordCount?: number;
  fileUrl?: string;
  error?: string;
}> {
  try {
    // 1. Claim the job (atomic guard against double-processing)
    const { data: claimed, error: claimErr } = await admin
      .from("export_jobs")
      .update({ status: "processing" })
      .eq("id", job.id)
      .eq("status", "queued") // only claim if still queued
      .select()
      .single();

    if (claimErr || !claimed) {
      // Either someone else claimed it, or it transitioned. Skip.
      return { ok: false, error: "Job already claimed by another worker" };
    }

    // 2. Fetch rows
    const rows = await fetchJobRows(admin, job);

    // 3. Generate CSV
    const csv = rowsToCSV(rows);
    const csvBytes = new TextEncoder().encode(csv);

    // 4. Upload to admin_exports/{admin_id}/{job_id}.csv
    const path = `${job.admin_id}/${job.id}.csv`;
    const { error: uploadErr } = await admin.storage
      .from(BUCKET_ADMIN_EXPORTS)
      .upload(path, csvBytes, {
        contentType: "text/csv",
        upsert: true,
      });
    if (uploadErr) throw uploadErr;

    // 5. Mint a 24h signed URL
    const { data: signed, error: signErr } = await admin.storage
      .from(BUCKET_ADMIN_EXPORTS)
      .createSignedUrl(path, SIGNED_URL_EXPIRY_SEC);
    if (signErr || !signed?.signedUrl) {
      throw signErr ?? new Error("Failed to mint signed URL");
    }

    // 6. Mark job completed
    const { error: updateErr } = await admin
      .from("export_jobs")
      .update({
        status: "completed",
        file_url: signed.signedUrl,
        record_count: rows.length,
        completed_at: new Date().toISOString(),
      })
      .eq("id", job.id);
    if (updateErr) throw updateErr;

    return { ok: true, recordCount: rows.length, fileUrl: signed.signedUrl };
  } catch (err) {
    const message = (err as Error).message ?? String(err);
    console.error(`[process-export-jobs] job ${job.id} failed:`, message);

    // Best-effort: mark the job failed so the admin sees something
    await admin
      .from("export_jobs")
      .update({
        status: "failed",
        error_message: message.slice(0, 1000),
        completed_at: new Date().toISOString(),
      })
      .eq("id", job.id);

    return { ok: false, error: message };
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = requireEnv("SUPABASE_URL");
    const serviceRoleKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
    const admin = createClient(supabaseUrl, serviceRoleKey);

    // 1. Pick up to MAX_JOBS_PER_INVOCATION queued jobs (oldest first)
    const { data: jobs, error: fetchErr } = await admin
      .from("export_jobs")
      .select("id, admin_id, table_name, filter_config, status")
      .eq("status", "queued")
      .order("created_at", { ascending: true })
      .limit(MAX_JOBS_PER_INVOCATION);

    if (fetchErr) throw fetchErr;

    if (!jobs || jobs.length === 0) {
      return new Response(
        JSON.stringify({ message: "No queued jobs", processed: 0 }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 2. Process them sequentially. Could parallelise but exports can be
    // memory-heavy and we'd rather be predictable than fast.
    const results = [];
    let succeeded = 0;
    let failed = 0;
    for (const job of jobs as ExportJob[]) {
      const r = await processJob(admin, job);
      results.push({ id: job.id, ...r });
      if (r.ok) succeeded++;
      else failed++;
    }

    return new Response(
      JSON.stringify({
        message: "Export batch complete",
        processed: jobs.length,
        succeeded,
        failed,
        results,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("[process-export-jobs] fatal:", err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
