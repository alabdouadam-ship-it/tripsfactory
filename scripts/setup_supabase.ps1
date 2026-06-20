# ============================================================================
# setup_supabase.ps1 — bring up the TripsFactory backend on a FRESH Supabase project (Windows).
#
# Applies SQL with `psql` (PostgreSQL 17 client) and uses the Supabase CLI for
# function deploys + secrets. Manual dashboard steps printed at the end.
#
# Usage (PowerShell):
#   $env:SUPABASE_PROJECT_REF      = 'xxxx'
#   $env:SUPABASE_PROJECT_URL      = 'https://xxxx.supabase.co'
#   $env:SUPABASE_DB_URL           = 'postgresql://postgres.xxxx:<PWD>@aws-...pooler.supabase.com:5432/postgres'
#   $env:SUPABASE_SERVICE_ROLE_KEY = 'sb_secret_...'
#   $env:FIREBASE_SERVICE_ACCOUNT_FILE = '.\firebase-adminsdk.json'   # optional
#   ./scripts/setup_supabase.ps1
# ============================================================================
$ErrorActionPreference = 'Stop'
foreach ($v in 'SUPABASE_PROJECT_REF','SUPABASE_PROJECT_URL','SUPABASE_DB_URL','SUPABASE_SERVICE_ROLE_KEY') {
  if (-not (Get-Item "env:$v" -ErrorAction SilentlyContinue)) { throw "Set environment variable $v" }
}
$ref = $env:SUPABASE_PROJECT_REF; $url = $env:SUPABASE_PROJECT_URL
$db  = $env:SUPABASE_DB_URL;      $key = $env:SUPABASE_SERVICE_ROLE_KEY
function PsqlFile($f) { psql $db -v ON_ERROR_STOP=1 -f $f; if ($LASTEXITCODE -ne 0) { throw "psql failed on $f" } }
# Resolve Supabase CLI: prefer global `supabase`, else `npx supabase`.
$script:UseNpx = -not (Get-Command supabase -ErrorAction SilentlyContinue)
function Supa { if ($script:UseNpx) { npx supabase @args } else { supabase @args } }

Write-Host "==> 1/6 Linking project $ref"
Supa link --project-ref $ref

Write-Host "==> 2/6 Applying database schema (migrations in order)"
$migrations = Get-ChildItem 'supabase/migrations/*.sql' | Sort-Object Name
if (-not $migrations) { throw "No migrations found in supabase/migrations/ (expected at least the baseline)." }
foreach ($m in $migrations) { Write-Host "    - $($m.Name)"; PsqlFile $m.FullName }

Write-Host "==> 3/6 Deploying Edge Functions"
foreach ($fn in 'push-notification','send-push-notification','admin-action','auto-expire-trips','process-export-jobs') {
  Write-Host "    - $fn"
  if ($fn -eq 'push-notification') {
    # Authenticated by PUSH_WEBHOOK_TOKEN (x-webhook-secret header), not a JWT,
    # so the gateway must not require a JWT.
    Supa functions deploy $fn --no-verify-jwt
  } else {
    Supa functions deploy $fn
  }
}

Write-Host "==> 4/6 Setting function secrets"
# Dedicated push-webhook secret: the notifications trigger authenticates to the
# push-notification function with this token (sent as x-webhook-secret), fully
# decoupled from the service-role key (whose injected format varies). Generated
# if not supplied; set here as a function secret AND stored in Vault (step 5) so
# the trigger can read it. Both must hold the same value.
$pushToken = $env:PUSH_WEBHOOK_TOKEN
if (-not $pushToken) { $pushToken = [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N') }
Supa secrets set "PUSH_WEBHOOK_TOKEN=$pushToken"
# NOTE: SUPABASE_SERVICE_ROLE_KEY is auto-injected into the edge runtime and
# cannot be set as a secret (the SUPABASE_ prefix is reserved). It is stored in
# Vault below (step 5) only for the CRON edge-function calls (auto-expire-trips,
# process-export-jobs), which send it as a Bearer token. So $env:SUPABASE_SERVICE_ROLE_KEY
# should be the value the runtime injects (the sb_secret_... key on new projects).
if ($env:FIREBASE_SERVICE_ACCOUNT_FILE -and (Test-Path $env:FIREBASE_SERVICE_ACCOUNT_FILE)) {
  Supa secrets set "FIREBASE_SERVICE_ACCOUNT=$(Get-Content $env:FIREBASE_SERVICE_ACCOUNT_FILE -Raw)"
} else { Write-Host "    ! FIREBASE_SERVICE_ACCOUNT_FILE not set - set FIREBASE_SERVICE_ACCOUNT manually." }

Write-Host "==> 5/6 Vault secrets + storage buckets + cron"
# service_role_key: used by the cron jobs' edge-function calls (Bearer token).
psql $db -v ON_ERROR_STOP=1 -c "select vault.create_secret('$key', 'service_role_key') where not exists (select 1 from vault.secrets where name='service_role_key');"
psql $db -v ON_ERROR_STOP=1 -c "select vault.update_secret((select id from vault.secrets where name='service_role_key'), '$key') where exists (select 1 from vault.secrets where name='service_role_key');"
# push_webhook_token: read by handle_new_notification() to authenticate to the
# push-notification function. Must match the PUSH_WEBHOOK_TOKEN function secret.
psql $db -v ON_ERROR_STOP=1 -c "select vault.create_secret('$pushToken', 'push_webhook_token') where not exists (select 1 from vault.secrets where name='push_webhook_token');"
psql $db -v ON_ERROR_STOP=1 -c "select vault.update_secret((select id from vault.secrets where name='push_webhook_token'), '$pushToken') where exists (select 1 from vault.secrets where name='push_webhook_token');"
$tmp = New-TemporaryFile
(Get-Content supabase/bootstrap.sql -Raw).Replace('<PROJECT_URL>', $url) | Set-Content $tmp -Encoding utf8
psql $db -v ON_ERROR_STOP=1 -f $tmp; Remove-Item $tmp

Write-Host "==> 6/6 Storage policies + reference seed"
PsqlFile 'supabase/storage_policies.sql'
PsqlFile 'supabase/seed.sql'

Write-Host @"

==> Done. REMAINING MANUAL STEPS (see docs/BACKEND_SETUP.md):
  - Auth -> URL config redirect URLs:
      io.supabase.tripsfactory://login-callback
      io.supabase.tripsfactory://reset-callback
  - Auth -> Providers: enable Email, Phone OTP, Google OAuth
  - Promote first admin: update public.profiles set is_admin=true where id='<UUID>';
  - Firebase: replace android/app/google-services.json and ios/Runner/GoogleService-Info.plist
  - Fill .env / admin/.env.local with SUPABASE_URL + anon key
"@
