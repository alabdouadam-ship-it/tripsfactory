#!/usr/bin/env bash
# ============================================================================
# setup_google_auth.sh - automate the SUPABASE side of Google Sign-In via the
# Supabase Management API: enable the Google provider and add the app's
# redirect URLs to the allow-list. No dashboard clicks needed.
#
# NOT automatable: creating the Google Cloud OAuth *client* (Google has no
# public API for consumer OAuth client IDs). Create that once in Google Cloud
# Console (Web application; Authorized redirect URI
# https://<REF>.supabase.co/auth/v1/callback), then pass its id/secret here.
#
# Usage:
#   export SUPABASE_ACCESS_TOKEN=sbp_...      # PAT: https://supabase.com/dashboard/account/tokens
#   export SUPABASE_PROJECT_REF=xxxxxxxxxxxxxxxxx
#   ./scripts/setup_google_auth.sh <google-client-id> <google-client-secret>
# Requires: curl, jq.
# ============================================================================
set -euo pipefail
CLIENT_ID="${1:?usage: setup_google_auth.sh <client-id> <client-secret>}"
CLIENT_SECRET="${2:?usage: setup_google_auth.sh <client-id> <client-secret>}"
: "${SUPABASE_ACCESS_TOKEN:?set SUPABASE_ACCESS_TOKEN (personal access token)}"
: "${SUPABASE_PROJECT_REF:?set SUPABASE_PROJECT_REF}"

REDIRECTS=("io.supabase.tripship://login-callback" "io.supabase.tripship://reset-callback")
BASE="https://api.supabase.com/v1/projects/${SUPABASE_PROJECT_REF}/config/auth"
AUTH=(-H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}")

echo "==> Reading current auth config for ${SUPABASE_PROJECT_REF}"
existing="$(curl -fsSL "${AUTH[@]}" "$BASE" | jq -r '.uri_allow_list // ""')"

# Merge the redirect allow-list (preserve anything already configured).
allow="$existing"
for r in "${REDIRECTS[@]}"; do
  case ",$allow," in
    *",$r,"*) : ;;                                  # already present
    *) if [[ -n "$allow" ]]; then allow="$allow,$r"; else allow="$r"; fi ;;
  esac
done

body="$(jq -n --arg id "$CLIENT_ID" --arg secret "$CLIENT_SECRET" --arg allow "$allow" \
  '{external_google_enabled:true, external_google_client_id:$id, external_google_secret:$secret, uri_allow_list:$allow}')"

echo "==> Enabling Google provider + setting redirect allow-list"
curl -fsSL -X PATCH "${AUTH[@]}" -H "Content-Type: application/json" -d "$body" "$BASE" >/dev/null
echo "Done. Google enabled; redirect allow-list = $allow"
echo "Reminder: the Google client's Authorized redirect URI must be https://${SUPABASE_PROJECT_REF}.supabase.co/auth/v1/callback"
