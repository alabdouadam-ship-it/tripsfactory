# ============================================================================
# setup_firebase_hosting.ps1 — interactively wire the two Firebase Hosting sites
# a fork needs (admin console + legal documents) on the fork's Firebase project.
#
# Flow:
#   1. Ensures you're logged in to the Firebase CLI (prompts `firebase login`).
#   2. Lets you pick the Firebase project (or set $env:FIREBASE_PROJECT_ID).
#   3. Lists the project's existing Hosting sites; for each role (admin, legal)
#      you choose an existing site OR create a new one (suggested id derived
#      from the brand name in fork.config.json, e.g. tripsfactory-admin / tripsfactory-legal).
#   4. Applies the deploy targets in .firebaserc.
#
# Non-interactive override: set $env:ADMIN_SITE_ID / $env:LEGAL_SITE_ID to skip
# the prompts (the site is created if it doesn't exist).
#
# Prereq: Firebase CLI (falls back to `npx firebase-tools`).
# ============================================================================
param([string]$ProjectId = $env:FIREBASE_PROJECT_ID)
$ErrorActionPreference = 'Stop'

$script:UseNpx = -not (Get-Command firebase -ErrorAction SilentlyContinue)
function Fb { if ($script:UseNpx) { npx firebase-tools @args } else { firebase @args } }

# 1. Authentication ----------------------------------------------------------
Write-Host '==> Checking Firebase authentication...'
Fb projects:list *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host '   Not authenticated - launching `firebase login`.'
  Fb login
}

# 2. Project -----------------------------------------------------------------
if (-not $ProjectId) {
  Write-Host ''
  Write-Host 'Your Firebase projects:'
  Fb projects:list
  $ProjectId = (Read-Host "`nEnter the Firebase project id to use").Trim()
}
if (-not $ProjectId) { throw 'No Firebase project id provided.' }

# 3. Suggested site-id slug (from the brand name) ----------------------------
$slug = $env:APP_SLUG
if (-not $slug) {
  try { $slug = (Get-Content fork.config.json -Raw | ConvertFrom-Json).brand.name } catch { $slug = 'app' }
}
$slug = ($slug -replace '[^a-zA-Z0-9]+', '-').Trim('-').ToLower()
if (-not $slug) { $slug = 'app' }

# Helpers --------------------------------------------------------------------
function Get-Sites {
  $raw = Fb hosting:sites:list --project $ProjectId --json 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $raw) { return @() }
  try {
    $obj = ($raw | Out-String | ConvertFrom-Json)
    return @($obj.result.sites | ForEach-Object { ($_.name -split '/')[-1] })
  } catch { return @() }
}

function New-Site([string]$siteId) {
  Write-Host "==> Creating hosting site '$siteId'..."
  Fb hosting:sites:create $siteId --project $ProjectId
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "  create returned non-zero for '$siteId' (it may already exist) - continuing."
  }
}

function Resolve-Site([string]$label, [string]$suggestedId, [string]$envValue, [string[]]$exclude) {
  if ($envValue) {
    if ((Get-Sites) -notcontains $envValue) { New-Site $envValue }
    Write-Host "==> $label site: '$envValue' (from environment)"
    return $envValue
  }
  $sites = @(Get-Sites | Where-Object { $exclude -notcontains $_ })
  Write-Host ''
  Write-Host "Choose the Firebase Hosting site for the ${label}:"
  for ($i = 0; $i -lt $sites.Count; $i++) { Write-Host ("  [{0}] {1}" -f ($i + 1), $sites[$i]) }
  if ($sites.Count -eq 0) { Write-Host '  (no available existing sites on this project)' }
  Write-Host "  [n] create a new site (suggested id: $suggestedId)"
  $ans = (Read-Host "Enter a number, 'n' to create, or type a site id").Trim()
  if ($ans -match '^[0-9]+$' -and [int]$ans -ge 1 -and [int]$ans -le $sites.Count) {
    return $sites[[int]$ans - 1]
  }
  if ($ans -eq '' -or $ans -ieq 'n') {
    $newId = (Read-Host "New site id [$suggestedId]").Trim()
    if (-not $newId) { $newId = $suggestedId }
    New-Site $newId
    return $newId
  }
  # Treat anything else as a literal site id (create it if it doesn't exist yet).
  if ((Get-Sites) -notcontains $ans) { New-Site $ans }
  return $ans
}

function Apply-Target([string]$target, [string]$siteId) {
  Write-Host "==> Wiring target '$target' -> site '$siteId'"
  Fb target:apply hosting $target $siteId --project $ProjectId
  if ($LASTEXITCODE -ne 0) { throw "target:apply failed for $target -> $siteId" }
}

# 4. Resolve both sites + wire targets ---------------------------------------
$adminId = Resolve-Site 'admin console' "$slug-admin" $env:ADMIN_SITE_ID @()
$legalId = Resolve-Site 'legal documents' "$slug-legal" $env:LEGAL_SITE_ID @($adminId)
Apply-Target 'admin' $adminId
Apply-Target 'legal' $legalId

Write-Host ''
Write-Host 'Done. Targets wired in .firebaserc:'
Write-Host "  admin -> $adminId  (https://$adminId.web.app)"
Write-Host "  legal -> $legalId  (https://$legalId.web.app)"
Write-Host ''
Write-Host 'Deploy:'
Write-Host "  admin:  cd admin; npm run build; cd ..; firebase deploy --only hosting:admin --project $ProjectId"
Write-Host "  legal:  firebase deploy --only hosting:legal --project $ProjectId"
Write-Host ''
Write-Host "Reminder: set BrandConfig.webBaseUrl to https://$legalId.web.app (legal site)."
