# ============================================================================
# set_fcm_secret.ps1 — set the FIREBASE_SERVICE_ACCOUNT Supabase edge secret
# from a Firebase service-account JSON file.
#
# Usage:
#   ./scripts/set_fcm_secret.ps1 -File supabase\secret\app-firebase-adminsdk.json
#   ./scripts/set_fcm_secret.ps1 -File <path> -ProjectRef xxxxxxxxxxxxxxxxx
#
# -ProjectRef is strongly recommended: `supabase secrets set` targets the
# CURRENTLY LINKED project, which may not be the one you intend.
# ============================================================================
param(
  [Parameter(Mandatory = $true)][string]$File,
  [string]$ProjectRef
)
$ErrorActionPreference = 'Stop'

# Resolve the Supabase CLI: prefer a global `supabase`, else fall back to `npx supabase`.
$script:UseNpx = -not (Get-Command supabase -ErrorAction SilentlyContinue)
function Supa { if ($script:UseNpx) { npx supabase @args } else { supabase @args } }

if (-not (Test-Path $File)) { throw "File not found: $File" }

# Validate it is real JSON and minify to a single line (keeps the \n escapes
# inside private_key, so the stored value stays valid JSON for JSON.parse).
try {
  $json = (Get-Content $File -Raw | ConvertFrom-Json | ConvertTo-Json -Compress -Depth 10)
} catch {
  throw "Not valid JSON: $File"
}

if ($ProjectRef) {
  Write-Host "Linking project $ProjectRef ..."
  Supa link --project-ref $ProjectRef
} else {
  Write-Warning "No -ProjectRef given; setting on the currently linked project."
}

# Use an --env-file to avoid shell-quoting issues with the JSON value.
# Single quotes => dotenv treats the value literally (JSON has no single quotes).
$tmp = [System.IO.Path]::GetTempFileName()
try {
  Set-Content -Path $tmp -Value ("FIREBASE_SERVICE_ACCOUNT='" + $json + "'") -Encoding utf8 -NoNewline
  Supa secrets set --env-file "$tmp"
  if ($LASTEXITCODE -ne 0) { throw "supabase secrets set failed (exit $LASTEXITCODE)" }
} finally {
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}

Write-Host "FIREBASE_SERVICE_ACCOUNT set successfully."
