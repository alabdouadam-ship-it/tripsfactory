#!/usr/bin/env bash
# ============================================================================
# set_fcm_secret.sh — set the FIREBASE_SERVICE_ACCOUNT Supabase edge secret
# from a Firebase service-account JSON file.
#
# Usage:
#   ./scripts/set_fcm_secret.sh <path-to-key.json> [project-ref]
#   ./scripts/set_fcm_secret.sh supabase/secret/app-firebase-adminsdk.json xxxxxxxxxxxxxxxxx
#
# The project ref is strongly recommended: `supabase secrets set` targets the
# CURRENTLY LINKED project otherwise.
# ============================================================================
set -euo pipefail
FILE="${1:?usage: set_fcm_secret.sh <key.json> [project-ref]}"
REF="${2:-}"

[[ -f "$FILE" ]] || { echo "File not found: $FILE" >&2; exit 1; }

# Validate + minify (requires jq for safety; falls back to raw if jq missing).
if command -v jq >/dev/null 2>&1; then
  JSON="$(jq -c . "$FILE")"
else
  JSON="$(tr -d '\n' < "$FILE")"
fi

# Resolve Supabase CLI: prefer global `supabase`, else `npx supabase`.
if command -v supabase >/dev/null 2>&1; then SUPA="supabase"; else SUPA="npx supabase"; fi
supa() { $SUPA "$@"; }

if [[ -n "$REF" ]]; then
  echo "Linking project $REF ..."
  supa link --project-ref "$REF"
else
  echo "WARNING: no project-ref given; setting on the currently linked project." >&2
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
printf "FIREBASE_SERVICE_ACCOUNT='%s'" "$JSON" > "$tmp"
supa secrets set --env-file "$tmp"

echo "FIREBASE_SERVICE_ACCOUNT set successfully."
