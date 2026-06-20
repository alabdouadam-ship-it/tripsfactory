# ============================================================================
# setup_google_auth.ps1 - automate the SUPABASE side of Google Sign-In via the
# Supabase Management API: enable the Google provider and add the app's
# redirect URLs to the allow-list. No dashboard clicks needed.
#
# NOT automatable: creating the Google Cloud OAuth *client* (Google has no
# public API for consumer OAuth client IDs). Create that once in Google Cloud
# Console (Web application; Authorized redirect URI
# https://<REF>.supabase.co/auth/v1/callback), then pass its id/secret here.
#
# Usage (PowerShell):
#   $env:SUPABASE_ACCESS_TOKEN = 'sbp_...'   # PAT: https://supabase.com/dashboard/account/tokens
#   $env:SUPABASE_PROJECT_REF  = 'xxxxxxxxxxxxxxxxx'
#   ./scripts/setup_google_auth.ps1 -ClientId '<google-client-id>' -ClientSecret '<google-client-secret>'
# ============================================================================
param(
  [Parameter(Mandatory)] [string]$ClientId,
  [Parameter(Mandatory)] [string]$ClientSecret,
  [string[]]$RedirectUrls = @(
    'io.supabase.tripsfactory://login-callback',
    'io.supabase.tripsfactory://reset-callback'
  )
)
$ErrorActionPreference = 'Stop'
$token = $env:SUPABASE_ACCESS_TOKEN; if (-not $token) { throw 'Set SUPABASE_ACCESS_TOKEN (personal access token)' }
$ref   = $env:SUPABASE_PROJECT_REF;  if (-not $ref)   { throw 'Set SUPABASE_PROJECT_REF' }
$base  = "https://api.supabase.com/v1/projects/$ref/config/auth"
$hdr   = @{ Authorization = "Bearer $token" }

Write-Host "==> Reading current auth config for $ref"
$cfg = Invoke-RestMethod -Method GET -Uri $base -Headers $hdr

# Merge the redirect allow-list (preserve anything already configured).
$existing = @()
if ($cfg.uri_allow_list) { $existing = $cfg.uri_allow_list -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
$allow = (($existing + $RedirectUrls) | Select-Object -Unique) -join ','

$body = @{
  external_google_enabled   = $true
  external_google_client_id = $ClientId
  external_google_secret    = $ClientSecret
  uri_allow_list            = $allow
} | ConvertTo-Json

Write-Host "==> Enabling Google provider + setting redirect allow-list"
Invoke-RestMethod -Method PATCH -Uri $base -Headers $hdr -ContentType 'application/json' -Body $body | Out-Null
Write-Host "Done. Google enabled; redirect allow-list = $allow"
Write-Host "Reminder: the Google client's Authorized redirect URI must be https://$ref.supabase.co/auth/v1/callback"
