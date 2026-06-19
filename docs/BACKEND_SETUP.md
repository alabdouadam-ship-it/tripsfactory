# Supabase & Firebase Setup Guide

This guide explains, simply and end-to-end, how to connect the app to a **fresh
Supabase project** and a **fresh Firebase project**. The codebase has no
hard-coded backend values — you provide credentials and run a script.

You set up **two** backends:

| Backend | Used for |
|---|---|
| **Supabase** | Database, Auth, Storage, Realtime, Edge Functions, cron |
| **Firebase** | Push notifications (FCM) + Analytics |

> This is the single backend guide: a friendly end-to-end walkthrough (Parts A–C),
> a scripts reference (Part D), and a detailed backend reference (Appendix).

---

# Part A — Supabase

## A1. Create the project
1. Go to https://supabase.com → **New project**.
2. Pick a name, a strong **database password** (save it), and a region.
3. Wait until it finishes provisioning.

## A2. Collect the credentials
From the project dashboard:
- **Settings → API**:
  - **Project URL** (e.g. `https://abcd.supabase.co`)
  - **anon public** key
  - **service_role** key — use the **`sb_secret_…`** value (the new-style key)
- **Settings → Database → Connection string (URI)** — the session-pooler string,
  used by the setup script (`SUPABASE_DB_URL`).

## A3. Put the keys where the apps read them
| App | File | Variables |
|---|---|---|
| Flutter | `.env` (repo root) | `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| Admin panel | `admin/.env.local` | `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` |

(Both files are gitignored — never commit keys.)

## A4. Provision the backend (one script)
Install the **Supabase CLI** and a **PostgreSQL 17** client (`psql`). Then set
the env vars and run the script — it applies the schema, extensions, storage
buckets, cron, realtime, storage policies, the locations seed, deploys the 5
edge functions, and sets the service-role + Vault secrets.

```powershell
# Windows PowerShell
$env:SUPABASE_PROJECT_REF      = 'abcd'
$env:SUPABASE_PROJECT_URL      = 'https://abcd.supabase.co'
$env:SUPABASE_DB_URL           = 'postgresql://postgres.abcd:<DB_PASSWORD>@aws-...pooler.supabase.com:5432/postgres'
$env:SUPABASE_SERVICE_ROLE_KEY = 'sb_secret_...'
$env:FIREBASE_SERVICE_ACCOUNT_FILE = '.\firebase-adminsdk.json'   # from Part B
./scripts/setup_supabase.ps1
```
(macOS/Linux: same env vars with `export`, then `./scripts/setup_supabase.sh`.)

> The full schema is the committed baseline migration
> `supabase/migrations/00000000000000_baseline.sql` (the single source of truth).
> The script applies every file in `supabase/migrations/` in order.

> **Push auth uses a dedicated `PUSH_WEBHOOK_TOKEN`, not the service-role key.**
> The setup script generates a random token, sets it as the `push-notification`
> function secret, and stores the same value in Vault (`push_webhook_token`); the
> notifications trigger sends it in the `x-webhook-secret` header. So push
> delivery no longer depends on the service-role key format. `SUPABASE_SERVICE_ROLE_KEY`
> should still be the new `sb_secret_...` key (the runtime-injected value) — it's
> stored in Vault (`service_role_key`) for the **cron** edge-function calls.
> To verify push auth, POST a dummy record to the function with header
> `x-webhook-secret: <token>` — a `200 {"message":"No token found"}` means auth is
> good; a `401 {"error":"Unauthorized"}` means the token doesn't match.

## A5. Manual dashboard steps (the script can't do these)
1. **Auth → URL Configuration** — add redirect URLs:
   - `io.supabase.tripship://login-callback`
   - `io.supabase.tripship://reset-callback`
2. **Auth → Providers** — enable what you use:
   - **Email/password** (on by default)
   - **Phone OTP** → also configure an SMS provider (e.g. Twilio) with its credentials
   - **Google** → add a Google OAuth client ID + secret
3. **Database → Extensions** — if any extension failed to enable via SQL, toggle it
   here: `pg_cron`, `pg_net`, `postgis`, `vault`, `pg_trgm`, `pgcrypto`.
4. **First admin user** — sign up once in the app/admin, then promote yourself.
   Easiest: run `scripts/make_user_admin.sql` in the SQL editor (edit the email
   first). Or inline:
   ```sql
   update public.profiles set is_admin = true where id = '<your-user-uuid>';
   ```
5. **App settings** (optional) — set the support WhatsApp number, min versions and
   banners from the admin panel’s Settings / In-App Messages pages.

That's Supabase done.

---

# Part B — Firebase (push notifications + analytics)

The app uses Firebase Cloud Messaging (FCM) for push. You bring your own
Firebase project and drop two config files into the app.

## B1. Create the Firebase project
1. Go to https://console.firebase.google.com → **Add project**.
2. (Analytics can be enabled or skipped — the app works either way.)

## B2. Add the Android app
1. In the project → **Add app → Android**.
2. **Android package name**: `com.tripship.app` (must match the app).
3. Download **`google-services.json`** and place it at:
   `android/app/google-services.json` (replace the existing one).

## B3. Add the iOS app
1. **Add app → iOS**.
2. **Bundle ID**: `com.tripship.app`.
3. Download **`GoogleService-Info.plist`** and place it at:
   `ios/Runner/GoogleService-Info.plist` (replace the existing one).

## B4. Enable Cloud Messaging + iOS push (APNs)
1. **Project Settings → Cloud Messaging** — make sure the Messaging API (v1) is enabled.
2. For **iOS push**, upload your Apple **APNs authentication key** (`.p8`) under
   **Cloud Messaging → Apple app configuration** (needed for real iOS devices).

## B5. Service account (so the server can send pushes)
The `push-notification` edge function sends FCM messages using a Firebase
**service account**. Generate it via **Firebase Console → Project Settings →
Service accounts → Generate new private key** (or in Google Cloud IAM, create a
service account with the **Firebase Cloud Messaging API Admin** role, then
**Keys → Add key → JSON**).

This JSON is a **secret** — it is NOT placed in the app or committed to git.
It goes into the Supabase **Edge Function secrets** as `FIREBASE_SERVICE_ACCOUNT`.
Set it one of three ways:

**1) Supabase Dashboard** — Edge Functions → Secrets → Add secret:
- Name: `FIREBASE_SERVICE_ACCOUNT`
- Value: paste the **entire** JSON file contents.

**2) Supabase CLI (PowerShell):**
```powershell
supabase link --project-ref <YOUR_PROJECT_REF>   # if not already linked
supabase secrets set "FIREBASE_SERVICE_ACCOUNT=$(Get-Content 'C:\path\to\your-key.json' -Raw)"
```
(bash: `supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat your-key.json)"`)

Or use the helper script (validates + minifies the JSON, avoids shell-quoting issues):
```powershell
./scripts/set_fcm_secret.ps1 -File supabase\secret\<key>.json -ProjectRef <YOUR_PROJECT_REF>
```
```bash
./scripts/set_fcm_secret.sh supabase/secret/<key>.json <YOUR_PROJECT_REF>
```

**3) Setup script** — put the file in the repo root named `firebase-adminsdk.json`
(already gitignored via `*firebase-adminsdk*.json`), then set
`FIREBASE_SERVICE_ACCOUNT_FILE` before running `scripts/setup_supabase.ps1` (Part A4).

> Rules: never commit the file; it must be the full valid JSON; its `project_id`
> must match the Firebase project whose `google-services.json` /
> `GoogleService-Info.plist` you put in the app.

---

# Part C — Google Sign-In (a login method)

> **iOS / Apple requirement (App Store Review Guideline 4.8).** Apple requires
> that any iOS app offering third-party/social login (like Google) **also** offer
> **Sign in with Apple**. This product ships with Apple Sign-In **not
> implemented**, so social sign-in (Google) is **hidden on iOS/macOS by default**
> (`AuthConfig.appleSignInEnabled = false` in `lib/core/config/auth_config.dart`).
> Email/phone login still work on iOS. To enable Google on iOS you must first
> implement **Sign in with Apple** (add `sign_in_with_apple`, wire the Apple
> button, enable the **Apple** provider in Supabase + the Apple Developer Service
> ID/key/return URLs), then set `AuthConfig.appleSignInEnabled = true`. On
> **Android**, Google works out of the box. See `docs/STORE_SUBMISSION.md`.

The app signs in with Google via **Supabase's OAuth redirect flow** (it opens a
browser → Google → back to Supabase → back into the app via the
`io.supabase.tripship://login-callback` deep link). You need a Web OAuth client,
the Supabase provider enabled, and the redirect URL allow-listed. The app-side
deep-link scheme is already configured.

## C1. Create a Web OAuth client (Google Cloud)
1. **Google Cloud Console → APIs & Services → OAuth consent screen** — configure
   it (External; app name; support email; scopes email + profile). In "Testing"
   mode only added test users can log in — **publish** it for public use.
2. **APIs & Services → Credentials → Create credentials → OAuth client ID**:
   - Application type: **Web application**
   - **Authorized redirect URI**: `https://<YOUR_PROJECT_REF>.supabase.co/auth/v1/callback`
3. Copy the **Client ID** and **Client Secret**.

## C2. Enable the Google provider in Supabase
- **Authentication → Providers → Google → Enable**.
- Paste the **Client ID** + **Client Secret** from C1.
- The callback URL Supabase shows (`https://<ref>.supabase.co/auth/v1/callback`)
  must exactly match the redirect URI set on the Google client.

## C3. Allow the app's deep-link return
- **Authentication → URL Configuration → Redirect URLs** — add:
  - `io.supabase.tripship://login-callback`
  - `io.supabase.tripship://reset-callback`

## C4. Automate C2 + C3 (optional)
C1 (the Google Cloud OAuth client) can't be scripted — Google has no public API
for creating consumer OAuth client IDs, so create it once by hand. But once you
have the client id/secret, **C2 and C3 are fully automatable** via the Supabase
Management API. Use the helper script (enables the Google provider and merges
the redirect URLs into the allow-list, no dashboard clicks):

```powershell
# PAT from https://supabase.com/dashboard/account/tokens
$env:SUPABASE_ACCESS_TOKEN = 'sbp_...'
$env:SUPABASE_PROJECT_REF  = '<your-project-ref>'
./scripts/setup_google_auth.ps1 -ClientId '<google-client-id>' -ClientSecret '<google-client-secret>'
```
```bash
export SUPABASE_ACCESS_TOKEN=sbp_...
export SUPABASE_PROJECT_REF=<your-project-ref>
./scripts/setup_google_auth.sh '<google-client-id>' '<google-client-secret>'   # needs curl + jq
```
The script GETs the current auth config first (so it won't clobber existing
redirect URLs), then PATCHes `external_google_enabled`/`client_id`/`secret` and
`uri_allow_list`. The same Management API can also set `site_url`, phone/email
providers, etc., if you want to extend it for a fork.

## Notes
- This flow needs **only the Web OAuth client** — no separate Android/iOS OAuth
  clients (those are for the native id-token flow, which this app does not use).
  `google-services.json` is for FCM, not for this login.
- Most failures are a mismatch: the Google client's redirect URI must be the
  Supabase `…/auth/v1/callback`, **and** `io.supabase.tripship://login-callback`
  must be in Supabase's Redirect URLs. If either is off you'll see
  "redirect not allowed" or the browser won't return to the app.

---

# Part D — Scripts reference

Every script lives in `scripts/`. PowerShell (`.ps1`) and bash (`.sh`) versions
are equivalent; use whichever matches your OS.

| Script | Purpose | Needs to succeed |
|---|---|---|
| `setup_supabase.ps1` / `.sh` | One-shot backend provision: schema (migrations) → functions → secrets → Vault → buckets/cron/realtime → storage policies → seed | Supabase CLI (authenticated), `psql` 17, `supabase/migrations/`, the 4 env vars |
| `set_fcm_secret.ps1` / `.sh` | Set the `FIREBASE_SERVICE_ACCOUNT` edge secret from a service-account JSON | Supabase CLI (authenticated), the JSON file |
| `setup_google_auth.ps1` / `.sh` | Enable the Google auth provider + add redirect URLs (Supabase Management API) | PAT, project ref, Google client id/secret (`.sh` also needs `curl` + `jq`) |
| `setup_firebase_hosting.ps1` / `.sh` | Interactively pick/create the two Firebase Hosting sites (admin console + legal docs) and wire deploy targets | Firebase CLI authenticated; `.sh` needs `jq` (project + site ids are chosen interactively) |
| `make_user_admin.sql` | Promote an existing user to admin (`is_admin = true`) | Run as `postgres` (SQL editor or psql) |
| `delete_user_data.sql` | Hard-delete ALL data for one user (dry-run by default) | Run as `postgres`; **irreversible** once confirmed |
| `test.sh` | Run the test suites (Flutter + optional DB + backend perf) | Flutter SDK; optional `tests/db/.env`, `tests/backend_tests/.env` |

## Common prerequisites
- **Supabase CLI** — if it isn't installed globally, the scripts fall back to
  `npx supabase` automatically. It must be **authenticated**: run
  `npx supabase login` once, or set `SUPABASE_ACCESS_TOKEN`.
- **psql** — a PostgreSQL **17** client on your `PATH` (the SQL files use v17).
- **Docker is NOT required.** `functions deploy` prints a harmless
  "Docker is not running" warning and deploys anyway.

## D1. `setup_supabase` — provision the whole backend
**Run (PowerShell):**
```powershell
$env:SUPABASE_PROJECT_REF          = 'abcd'
$env:SUPABASE_PROJECT_URL          = 'https://abcd.supabase.co'
$env:SUPABASE_DB_URL               = 'postgresql://postgres.abcd:<DB_PASSWORD>@aws-0-<region>.pooler.supabase.com:5432/postgres'
$env:SUPABASE_SERVICE_ROLE_KEY     = 'sb_secret_...'              # NEW secret key, not the legacy JWT
$env:FIREBASE_SERVICE_ACCOUNT_FILE = 'supabase/secret/<key>.json' # optional
./scripts/setup_supabase.ps1
```
(bash: same vars with `export`, then `./scripts/setup_supabase.sh`.)

**Inputs:** four required env vars above + optional `FIREBASE_SERVICE_ACCOUNT_FILE`.
The DB URL password must be URL-encoded if it contains special characters
(e.g. `@` → `%40`), or pass it via `PGPASSWORD` and a URL without the password.

**Needs:** the `supabase/migrations/` baseline present; `psql` 17; authenticated CLI.

**What success looks like:** runs 6 steps with no `ERROR`, ending at the
"REMAINING MANUAL STEPS" banner. Verify with:
```sql
select (select count(*) from storage.buckets)                              as buckets,        -- 6
       (select count(*) from cron.job)                                     as cron_jobs,      -- 4
       (select count(*) from public.locations)                             as seed_locations, -- 14
       (select count(*) from pg_publication_tables
          where pubname='supabase_realtime' and schemaname='public')       as realtime_tbls;  -- 5
```
Edge functions: `npx supabase functions list --project-ref <ref>` shows 5 ACTIVE.

**Notes:** designed for an **empty** project. Re-running against an
already-provisioned DB stops at the schema step with "already exists" (the
schema dump isn't idempotent). To re-apply only the idempotent post-schema bits,
run `bootstrap.sql` alone:
```powershell
(Get-Content supabase/bootstrap.sql -Raw).Replace('<PROJECT_URL>','https://<ref>.supabase.co') | psql $env:SUPABASE_DB_URL -v ON_ERROR_STOP=1 -f -
```

## D2. `set_fcm_secret` — push service-account secret
**Run:**
```powershell
./scripts/set_fcm_secret.ps1 -File supabase\secret\<key>.json -ProjectRef <ref>
```
```bash
./scripts/set_fcm_secret.sh supabase/secret/<key>.json <ref>
```
**Inputs:** path to the Firebase service-account JSON; project ref (strongly
recommended — without it the secret is set on the *currently linked* project).

**Needs:** authenticated Supabase CLI; a valid JSON file. The script validates +
minifies the JSON (keeps the `private_key` `\n` escapes) and sets it via an
`--env-file` to avoid shell-quoting issues.

**Success:** prints `FIREBASE_SERVICE_ACCOUNT set successfully.` Confirm with
`npx supabase secrets list --project-ref <ref>`.

## D3. `setup_google_auth` — Google provider + redirect URLs
**Run:**
```powershell
$env:SUPABASE_ACCESS_TOKEN = 'sbp_...'   # PAT: supabase.com/dashboard/account/tokens
$env:SUPABASE_PROJECT_REF  = '<ref>'
./scripts/setup_google_auth.ps1 -ClientId '<id>' -ClientSecret '<secret>'
```
```bash
export SUPABASE_ACCESS_TOKEN=sbp_...
export SUPABASE_PROJECT_REF=<ref>
./scripts/setup_google_auth.sh '<id>' '<secret>'    # needs curl + jq
```
**Inputs:** `SUPABASE_ACCESS_TOKEN` (personal access token), `SUPABASE_PROJECT_REF`,
the Google **client id** + **secret** (from Part C1, created manually).

**Needs:** a PAT with account access; `.sh` also needs `curl` and `jq`.

**Success:** prints `Done. Google enabled; redirect allow-list = ...`. It merges
(doesn't replace) the existing redirect URLs. The Google client's Authorized
redirect URI must still be `https://<ref>.supabase.co/auth/v1/callback`.

## D3b. `setup_firebase_hosting` — create/wire the hosting sites
Interactively wires the two Firebase Hosting sites a fork needs — the **admin
console** and the **legal documents** — and applies their deploy targets in
`.firebaserc`. Run once per fork.

It (1) ensures you're logged in (`firebase login`), (2) lets you pick the
Firebase project, (3) **lists the project's existing Hosting sites** and, for
each role, lets you **choose an existing site or create a new one** (suggested
id derived from the brand name in `fork.config.json`, e.g. `tripship-admin` /
`tripship-legal`), then (4) applies the targets.

```powershell
./scripts/setup_firebase_hosting.ps1                 # fully interactive
$env:FIREBASE_PROJECT_ID = 'your-project'            # optional: skip the project prompt
```
```bash
./scripts/setup_firebase_hosting.sh                  # needs jq
# Non-interactive: pre-set the ids to skip the prompts
ADMIN_SITE_ID=brand-admin LEGAL_SITE_ID=brand-legal FIREBASE_PROJECT_ID=your-project ./scripts/setup_firebase_hosting.sh
```
**Inputs:** none required (interactive). Optional env: `FIREBASE_PROJECT_ID`,
`ADMIN_SITE_ID`, `LEGAL_SITE_ID`, `APP_SLUG`. **Needs:** Firebase CLI
authenticated (falls back to `npx firebase-tools`); `.sh` also needs `jq`.
Firebase site ids are **globally unique**, so each fork picks its own.

**Success:** both targets resolve to a site and `firebase deploy --only
hosting:admin` / `:legal` work. Then build + deploy the admin (`admin/deploy.sh`)
and deploy the static legal site (`public/`). Set `BrandConfig.webBaseUrl` to the
legal site URL.

## D4. `make_user_admin.sql` — promote an admin
Open in the **Supabase SQL editor**, change the `v_email` value, and Run (it runs
as `postgres`, which bypasses RLS and the admin-column protection triggers).
Idempotent; if the user is already admin it does nothing, and it prints the full
admin list at the end. Requires the user to have signed up first.

## D5. `delete_user_data.sql` — wipe one user (danger)
**Irreversible.** Open in the SQL editor, set `v_email`. It is **dry-run by
default** (`v_confirm := false`) — it only prints the counts of what *would* be
deleted. To actually delete, set `v_confirm := true` and re-run. It removes all
rows the user owns/created and their storage files, nulls them out as an
admin-actor on other users' records (preserving those), then deletes the profile
and the `auth.users` row.

## D6. `test.sh` — run the test suites
```bash
./scripts/test.sh
```
Runs `flutter pub get` + `flutter test`. Also runs the DB tests if
`tests/db/.env` exists, and the backend perf tests if `tests/backend_tests/.env`
exists (both are skipped with a message otherwise). Needs the Flutter SDK; the
DB/backend tests need Node + their `.env` (copy from the `.env.example`).

---

# Where each value goes (cheat sheet)

| Value | From | Goes to |
|---|---|---|
| Supabase URL + anon key | Supabase → Settings → API | `.env`, `admin/.env.local` |
| Service-role (`sb_secret`) key | Supabase → Settings → API | setup env + edge secret + Vault `service_role_key` |
| DB connection string | Supabase → Settings → Database | setup env `SUPABASE_DB_URL` |
| `google-services.json` | Firebase → Android app | `android/app/` |
| `GoogleService-Info.plist` | Firebase → iOS app | `ios/Runner/` |
| Firebase service account JSON | Firebase → Service accounts | Supabase edge secret `FIREBASE_SERVICE_ACCOUNT` |
| Google OAuth client id + secret | Google Cloud → Credentials | Supabase Google provider (or `setup_google_auth` script) |
| Personal access token (`sbp_`) | supabase.com/dashboard/account/tokens | `setup_google_auth` env `SUPABASE_ACCESS_TOKEN` |

# Final checklist
- [ ] Supabase project created; keys in `.env` + `admin/.env.local`
- [ ] `scripts/setup_supabase.ps1` ran clean (schema + buckets + cron + realtime + policies + seed + functions + secrets)
- [ ] Auth redirect URLs + providers configured
- [ ] Google Sign-In: Web OAuth client created, Google provider enabled, redirect URLs allow-listed
- [ ] First admin promoted (`is_admin = true`)
- [ ] Firebase project created; `google-services.json` + `GoogleService-Info.plist` replaced
- [ ] APNs key uploaded (for iOS push)
- [ ] `FIREBASE_SERVICE_ACCOUNT` edge secret set
- [ ] Rebuild the app — it points at the new backends with no code changes

---

# Appendix — backend reference

Granular detail behind what `scripts/setup_supabase.*` provisions. You normally
don't run these by hand (the script does), but they're documented for
verification and for forks that re-orient the backend.

## Environment variables (the only "config")

| Surface | File | Keys |
|---|---|---|
| Flutter app | `.env` (repo root, gitignored) | `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| Admin panel | `admin/.env.local` | `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` |
| DB test suite | `tests/db/.env` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`, `TEST_USER_*` |

There is no committed `supabase/config.toml`; pointing at a new project is
entirely env-driven.

## Schema (single source of truth)

The complete schema is one baseline migration:
`supabase/migrations/00000000000000_baseline.sql` (extensions + all tables,
enums, functions, triggers, RLS policies, indexes). The setup script applies
every file in `supabase/migrations/` in lexical order with `psql`. To evolve the
schema later, add a new timestamped migration file next to the baseline; never
re-run the baseline against a populated database.

Required extensions: `pgcrypto`, `pg_cron`, `pg_net`, `supabase_vault`,
`postgis`, `pg_trgm`, `uuid-ossp`, `pg_stat_statements`.

## Storage buckets

Names are defined in `lib/core/config/storage_buckets.dart` and must match.

| Bucket | Visibility |
|---|---|
| `user_documents` | **Private** (KYC docs; signed-URL access) |
| `chat-attachments` | **Private** (participant-gated signed URLs) |
| `admin_exports` | **Private** (24h signed URLs) |
| `avatars` | Public-read |
| `shipment_photos` | Public-read |
| `ads` | Public-read, admin-write |

## Edge functions & `verify_jwt`

Five functions in `supabase/functions/`:

| Function | `verify_jwt` | Auth model |
|---|---|---|
| `push-notification` | **false** (`--no-verify-jwt`) | DB webhook authed by `PUSH_WEBHOOK_TOKEN` (`x-webhook-secret` header) |
| `send-push-notification` | false | in-function `getUser` + `is_admin` check |
| `admin-action` | true/false | verifies caller JWT + `is_admin()` in-function |
| `process-export-jobs` | **true** | — |
| `auto-expire-trips` | — | invoked by cron with the service-role key |

## Vault secrets (DB → edge-function calls)

- `push_webhook_token` — read by `handle_new_notification` to authenticate to the
  `push-notification` function (matches the `PUSH_WEBHOOK_TOKEN` function secret).
- `service_role_key` — used by the **cron** jobs as a Bearer token. Store the
  new-style `sb_secret_...` value (the runtime-injected service-role key).

## pg_cron jobs

- `auto-expire-trips` — every 15 min → calls the `auto-expire-trips` function.
- `expire_pending_shipments_job` — every 30 min → `public.fn_expire_pending_shipments()`.
- `process-export-jobs` — every 5 min → calls the `process-export-jobs` function.

The cron commands read the service key from Vault inline:
`'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name='service_role_key')`.

## DB test users (only for the SQL test suite / CI)

Create the three users referenced by `tests/db/.env`
(`TEST_USER_REQUESTER_*`, `TEST_USER_TRAVELER_*`, `TEST_USER_ADMIN_*`), then:
`cd tests/db && npm install && npm test`.
