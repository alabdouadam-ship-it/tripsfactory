#!/usr/bin/env bash
# ============================================================================
# setup_supabase.sh — bring up the TripShip backend on a FRESH Supabase project.
#
# Applies SQL with `psql` (from a PostgreSQL 17 client) and uses the Supabase
# CLI for function deploys + secrets. Manual dashboard steps (auth redirect
# URLs, OAuth providers, first admin user, Firebase config files) are printed
# at the end — see docs/BACKEND_SETUP.md.
#
# Usage:
#   export SUPABASE_PROJECT_REF=xxxx
#   export SUPABASE_PROJECT_URL=https://xxxx.supabase.co
#   export SUPABASE_DB_URL='postgresql://postgres.xxxx:<PWD>@aws-...pooler.supabase.com:5432/postgres'
#   export SUPABASE_SERVICE_ROLE_KEY=sb_secret_...
#   export FIREBASE_SERVICE_ACCOUNT_FILE=./firebase-adminsdk.json   # optional
#   ./scripts/setup_supabase.sh
# ============================================================================
set -euo pipefail
: "${SUPABASE_PROJECT_REF:?set SUPABASE_PROJECT_REF}"
: "${SUPABASE_PROJECT_URL:?set SUPABASE_PROJECT_URL}"
: "${SUPABASE_DB_URL:?set SUPABASE_DB_URL (psql connection string)}"
: "${SUPABASE_SERVICE_ROLE_KEY:?set SUPABASE_SERVICE_ROLE_KEY}"

psql_run() { psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 "$@"; }
# Resolve Supabase CLI: prefer `supabase`, else `npx supabase`.
if command -v supabase >/dev/null 2>&1; then SUPA="supabase"; else SUPA="npx supabase"; fi
supa() { $SUPA "$@"; }

echo "==> 1/6 Linking project $SUPABASE_PROJECT_REF"
supa link --project-ref "$SUPABASE_PROJECT_REF"

echo "==> 2/6 Applying database schema (migrations in order)"
shopt -s nullglob
migrations=(supabase/migrations/*.sql)
if [[ ${#migrations[@]} -eq 0 ]]; then
  echo "    !! No migrations found in supabase/migrations/ (expected at least the baseline)." >&2
  exit 1
fi
while IFS= read -r m; do
  echo "    - $(basename "$m")"
  psql_run -f "$m"
done < <(printf '%s\n' "${migrations[@]}" | sort)

echo "==> 3/6 Deploying Edge Functions"
for fn in push-notification send-push-notification admin-action auto-expire-trips process-export-jobs; do
  echo "    - $fn"
  if [[ "$fn" == "push-notification" ]]; then
    # Authenticated by PUSH_WEBHOOK_TOKEN (x-webhook-secret), not a JWT.
    supa functions deploy "$fn" --no-verify-jwt
  else
    supa functions deploy "$fn"
  fi
done

echo "==> 4/6 Setting function secrets"
# Dedicated push-webhook secret: the notifications trigger authenticates to the
# push-notification function with this token (sent as x-webhook-secret), fully
# decoupled from the service-role key. Generated if not supplied; set here as a
# function secret AND stored in Vault (step 5) so the trigger can read it.
PUSH_WEBHOOK_TOKEN="${PUSH_WEBHOOK_TOKEN:-$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | xxd -p | tr -d '\n')}"
supa secrets set "PUSH_WEBHOOK_TOKEN=${PUSH_WEBHOOK_TOKEN}"
# NOTE: SUPABASE_SERVICE_ROLE_KEY is auto-injected into the edge runtime and
# cannot be set as a secret (SUPABASE_ prefix is reserved). It is stored in Vault
# below only for the CRON edge-function calls (auto-expire-trips, process-export-jobs),
# which send it as a Bearer token — so it should be the value the runtime injects
# (the sb_secret_... key on new projects).
if [[ -n "${FIREBASE_SERVICE_ACCOUNT_FILE:-}" && -f "${FIREBASE_SERVICE_ACCOUNT_FILE}" ]]; then
  supa secrets set FIREBASE_SERVICE_ACCOUNT="$(cat "$FIREBASE_SERVICE_ACCOUNT_FILE")"
else
  echo "    ! FIREBASE_SERVICE_ACCOUNT_FILE not set — set FIREBASE_SERVICE_ACCOUNT manually."
fi

echo "==> 5/6 Vault secrets + storage buckets + cron"
# service_role_key: used by the cron jobs' edge-function calls (Bearer token).
psql_run -c "select vault.create_secret('${SUPABASE_SERVICE_ROLE_KEY}', 'service_role_key') where not exists (select 1 from vault.secrets where name='service_role_key');"
psql_run -c "select vault.update_secret((select id from vault.secrets where name='service_role_key'), '${SUPABASE_SERVICE_ROLE_KEY}') where exists (select 1 from vault.secrets where name='service_role_key');"
# push_webhook_token: read by handle_new_notification() to authenticate to the
# push-notification function. Must match the PUSH_WEBHOOK_TOKEN function secret.
psql_run -c "select vault.create_secret('${PUSH_WEBHOOK_TOKEN}', 'push_webhook_token') where not exists (select 1 from vault.secrets where name='push_webhook_token');"
psql_run -c "select vault.update_secret((select id from vault.secrets where name='push_webhook_token'), '${PUSH_WEBHOOK_TOKEN}') where exists (select 1 from vault.secrets where name='push_webhook_token');"
sed "s#<PROJECT_URL>#${SUPABASE_PROJECT_URL}#g" supabase/bootstrap.sql | psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f -

echo "==> 6/6 Storage policies + reference seed"
psql_run -f supabase/storage_policies.sql
psql_run -f supabase/seed.sql

cat <<EOF

==> Done. REMAINING MANUAL STEPS (see docs/BACKEND_SETUP.md):
  - Auth → URL config redirect URLs:
      io.supabase.tripship://login-callback
      io.supabase.tripship://reset-callback
  - Auth → Providers: enable Email, Phone OTP, Google OAuth as needed
  - Promote first admin: update public.profiles set is_admin=true where id='<UUID>';
  - Firebase: replace android/app/google-services.json and ios/Runner/GoogleService-Info.plist
  - Fill .env / admin/.env.local with SUPABASE_URL + anon key
EOF
