#!/usr/bin/env bash
# ============================================================================
# setup_firebase_hosting.sh — interactively wire the two Firebase Hosting sites
# a fork needs (admin console + legal documents) on the fork's Firebase project.
#
# Flow:
#   1. Ensures you're logged in to the Firebase CLI (prompts `firebase login`).
#   2. Lets you pick the Firebase project (or set FIREBASE_PROJECT_ID).
#   3. Lists the project's existing Hosting sites; for each role (admin, legal)
#      you choose an existing site OR create a new one (suggested id derived
#      from the brand name in fork.config.json, e.g. tripship-admin / tripship-legal).
#   4. Applies the deploy targets in .firebaserc.
#
# Non-interactive override: set ADMIN_SITE_ID / LEGAL_SITE_ID to skip the
# prompts (the site is created if it doesn't exist).
#
# Prereq: Firebase CLI (falls back to `npx firebase-tools`), plus `jq`.
# ============================================================================
set -euo pipefail

if command -v firebase >/dev/null 2>&1; then FB="firebase"; else FB="npx firebase-tools"; fi
fb() { $FB "$@"; }

# 1. Authentication ----------------------------------------------------------
echo "==> Checking Firebase authentication..."
if ! fb projects:list >/dev/null 2>&1; then
  echo "   Not authenticated - launching 'firebase login'."
  fb login
fi

# 2. Project -----------------------------------------------------------------
PROJECT_ID="${FIREBASE_PROJECT_ID:-}"
if [[ -z "$PROJECT_ID" ]]; then
  echo ""
  echo "Your Firebase projects:"
  fb projects:list
  read -r -p $'\nEnter the Firebase project id to use: ' PROJECT_ID
fi
[[ -n "$PROJECT_ID" ]] || { echo "No Firebase project id provided." >&2; exit 1; }

# 3. Suggested site-id slug (from the brand name) ----------------------------
SLUG="${APP_SLUG:-}"
if [[ -z "$SLUG" ]]; then SLUG="$(jq -r '.brand.name // "app"' fork.config.json 2>/dev/null || echo app)"; fi
SLUG="$(printf '%s' "$SLUG" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//')"
[[ -n "$SLUG" ]] || SLUG="app"

# Helpers (prompts go to stderr so the chosen id is the only stdout) ----------
get_sites() {
  fb hosting:sites:list --project "$PROJECT_ID" --json 2>/dev/null \
    | jq -r '.result.sites[]?.name | split("/") | .[-1]' 2>/dev/null || true
}

create_site() {
  echo "==> Creating hosting site '$1'..." >&2
  fb hosting:sites:create "$1" --project "$PROJECT_ID" >&2 \
    || echo "    (create non-zero for '$1' - it may already exist, continuing)" >&2
}

resolve_site() {
  local label="$1" suggested="$2" envv="$3"; shift 3
  local exclude=("$@")
  if [[ -n "$envv" ]]; then
    get_sites | grep -qx "$envv" || create_site "$envv"
    echo "==> $label site: '$envv' (from environment)" >&2
    printf '%s' "$envv"; return
  fi
  local all=() s skip e
  while IFS= read -r s; do
    [[ -z "$s" ]] && continue
    skip=0; for e in "${exclude[@]:-}"; do [[ "$e" == "$s" ]] && skip=1; done
    [[ $skip -eq 0 ]] && all+=("$s")
  done < <(get_sites)
  {
    echo ""
    echo "Choose the Firebase Hosting site for the $label:"
    local i=1; for s in "${all[@]:-}"; do [[ -n "$s" ]] && echo "  [$i] $s" && i=$((i+1)); done
    [[ ${#all[@]} -eq 0 ]] && echo "  (no available existing sites on this project)"
    echo "  [n] create a new site (suggested id: $suggested)"
  } >&2
  read -r -p "Enter a number, 'n' to create, or type a site id: " ans
  if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans >= 1 && ans <= ${#all[@]} )); then
    printf '%s' "${all[$((ans-1))]}"; return
  fi
  if [[ -z "$ans" || "$ans" == "n" || "$ans" == "N" ]]; then
    read -r -p "New site id [$suggested]: " newid
    [[ -n "$newid" ]] || newid="$suggested"
    create_site "$newid"; printf '%s' "$newid"; return
  fi
  get_sites | grep -qx "$ans" || create_site "$ans"
  printf '%s' "$ans"
}

# 4. Resolve both sites + wire targets ---------------------------------------
ADMIN_ID="$(resolve_site 'admin console' "$SLUG-admin" "${ADMIN_SITE_ID:-}")"
LEGAL_ID="$(resolve_site 'legal documents' "$SLUG-legal" "${LEGAL_SITE_ID:-}" "$ADMIN_ID")"

echo "==> Wiring target 'admin' -> '$ADMIN_ID'"
fb target:apply hosting admin "$ADMIN_ID" --project "$PROJECT_ID"
echo "==> Wiring target 'legal' -> '$LEGAL_ID'"
fb target:apply hosting legal "$LEGAL_ID" --project "$PROJECT_ID"

cat <<EOF

Done. Targets wired in .firebaserc:
  admin -> $ADMIN_ID  (https://$ADMIN_ID.web.app)
  legal -> $LEGAL_ID  (https://$LEGAL_ID.web.app)

Deploy:
  admin:  (cd admin && npm run build) && firebase deploy --only hosting:admin --project $PROJECT_ID
  legal:  firebase deploy --only hosting:legal --project $PROJECT_ID

Reminder: set BrandConfig.webBaseUrl to https://$LEGAL_ID.web.app (legal site).
EOF
