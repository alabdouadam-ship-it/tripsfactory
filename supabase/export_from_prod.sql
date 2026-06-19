-- ============================================================================
-- export_from_prod.sql — run this in the Supabase Dashboard SQL Editor on the
-- EXISTING project, then copy the single JSON result cell and send it back.
--
-- It is READ-ONLY and contains NO secrets (no keys, no Vault values). It returns
-- the runtime objects + reference data that the repo migrations don't fully
-- reproduce on a fresh project: locations seed, cron jobs, storage buckets +
-- policies, extensions, the seeded config tables, and the applied migration list
-- (to confirm repo ↔ prod parity).
-- ============================================================================
select jsonb_pretty(jsonb_build_object(
  'migrations',       (select jsonb_agg(version order by version)
                         from supabase_migrations.schema_migrations),
  'extensions',       (select jsonb_agg(jsonb_build_object('name', extname,
                         'schema', extnamespace::regnamespace::text))
                         from pg_extension),
  'cron_jobs',        (select jsonb_agg(jsonb_build_object('jobname', jobname,
                         'schedule', schedule, 'command', command, 'active', active))
                         from cron.job),
  'storage_buckets',  (select jsonb_agg(jsonb_build_object('id', id, 'public', public,
                         'file_size_limit', file_size_limit,
                         'allowed_mime_types', allowed_mime_types))
                         from storage.buckets),
  'storage_policies', (select jsonb_agg(jsonb_build_object('policyname', policyname,
                         'cmd', cmd, 'roles', roles, 'qual', qual, 'with_check', with_check))
                         from pg_policies where schemaname = 'storage'),
  'vault_secret_names',(select jsonb_agg(name) from vault.secrets),
  'risk_config',      (select jsonb_agg(r) from public.risk_config r),
  'app_settings',     (select jsonb_agg(a) from public.app_settings a),
  'locations',        (select jsonb_agg(l) from public.locations l)
)) as export;
