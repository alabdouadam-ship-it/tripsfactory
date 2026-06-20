-- ============================================================================
-- bootstrap.sql — post-schema provisioning for a FRESH TripShip project.
--
-- Run AFTER the schema exists (see SUPABASE_SETUP.md). Creates Storage buckets
-- (with the exact settings from the source project) and the pg_cron jobs.
-- Idempotent — safe to re-run.
--
-- Replace <PROJECT_URL> with your project URL (the setup script does this), and
-- ensure the Vault secret 'service_role_key' exists (SUPABASE_SETUP.md §6).
-- Storage RLS policies live in supabase/storage_policies.sql (run that too).
-- ============================================================================

-- 1. Storage buckets (settings mirror the source project) ----------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('user_documents',  'user_documents',  false, null, null),
  ('chat-attachments','chat-attachments', false, null, null),
  ('avatars',         'avatars',          true,  null, null),
  ('ads',             'ads',              true,  null, null),
  ('admin_exports',   'admin_exports',    false, 104857600,
     array['text/csv','application/zip','application/json']),
  -- delivery_photos is referenced by the app (booking handshake photos) but did
  -- not exist in the source project. Created here so that code path works.
  ('delivery_photos', 'delivery_photos',  true,  null, null)
on conflict (id) do nothing;

-- 2. pg_cron jobs (idempotent: unschedule-if-exists, then schedule) ------------
do $$
begin
  -- expire past trips — every 5 min (plain SQL fn)
  perform cron.unschedule('expire_past_trips_job') where exists (select 1 from cron.job where jobname='expire_past_trips_job');
  perform cron.schedule('expire_past_trips_job', '*/5 * * * *', 'SELECT public.fn_expire_past_trips()');

  -- auto-expire-trips edge fn — every 15 min
  perform cron.unschedule('auto-expire-trips') where exists (select 1 from cron.job where jobname='auto-expire-trips');
  perform cron.schedule('auto-expire-trips', '*/15 * * * *', $cmd$
    SELECT net.http_post(
      url := '<PROJECT_URL>/functions/v1/auto-expire-trips',
      headers := jsonb_build_object('Authorization',
        'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name='service_role_key'),
        'Content-Type','application/json'),
      body := '{}'::jsonb,
      timeout_milliseconds := 15000) AS request_id;
  $cmd$);

  -- process-export-jobs edge fn — every 5 min
  perform cron.unschedule('process-export-jobs') where exists (select 1 from cron.job where jobname='process-export-jobs');
  perform cron.schedule('process-export-jobs', '*/5 * * * *', $cmd$
    SELECT net.http_post(
      url := '<PROJECT_URL>/functions/v1/process-export-jobs',
      headers := jsonb_build_object('Authorization',
        'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name='service_role_key'),
        'Content-Type','application/json'),
      body := '{}'::jsonb,
      timeout_milliseconds := 30000) AS request_id;
  $cmd$);
end $$;

-- 3. Realtime — add tables to the supabase_realtime publication ----------------
-- NOT captured by a public-schema pg_dump, so it must be re-applied here.
-- The Flutter app uses .stream()/realtime on these tables (chat, notifications,
-- live trip/profile updates). Idempotent.
do $$
declare t text;
begin
  foreach t in array array['notifications','messages','trips','profiles','support_messages'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname='supabase_realtime' and schemaname='public' and tablename=t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- 4. Push webhook — point the notifications trigger at THIS project ------------
-- The baseline schema ships handle_new_notification() with the SOURCE project's
-- URL hardcoded. On a fresh project that would POST every push to the wrong
-- (old) project's edge function, so FCM delivery would silently fail while
-- in-app notification rows still get written. Recreate the function here with
-- <PROJECT_URL> (substituted by the setup script) so pushes hit this project's
-- push-notification function.
--
-- Auth: a DEDICATED webhook secret (Vault 'push_webhook_token'), sent in the
-- x-webhook-secret header and matched against the function's PUSH_WEBHOOK_TOKEN
-- env. This is decoupled from the service-role key (whose injected format
-- varies), so the trigger->function hop no longer depends on key format.
create or replace function public.handle_new_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token text;
begin
  select decrypted_secret into v_token
  from vault.decrypted_secrets
  where name = 'push_webhook_token'
  limit 1;

  perform net.http_post(
    url := '<PROJECT_URL>/functions/v1/push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', coalesce(v_token, '')
    ),
    body := jsonb_build_object('record', row_to_json(new)),
    timeout_milliseconds := 5000
  );
  return new;
end;
$$;

-- Ensure the trigger exists (dump already creates it, but be safe on a fresh DB).
drop trigger if exists on_notification_created on public.notifications;
create trigger on_notification_created
  after insert on public.notifications
  for each row execute function public.handle_new_notification();
