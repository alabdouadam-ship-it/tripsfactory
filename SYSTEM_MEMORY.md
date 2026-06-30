# TripsFactory — System Memory

A single, practical reference for the whole system (app + admin + backend + websites),
plus the open findings. Scoped for a small team — no over-engineering, just what matters.

_Last full scan: Jun 2026 (post trips-only reorientation + TripShip→TripsFactory rebrand)._

---

## 1. What it is
A white-label **trips-only logistics marketplace**. Drivers/travelers post **trips**
(route A→B with capacity); users browse and **book/apply**; they negotiate in
announcement-scoped **chat**; completion is a **dual-confirmation handshake + delivery
OTP**; then both sides **rate**. No in-app payments, no live GPS — completion is a
manual/OTP handshake. The old company/shipment/offer side has been fully removed.

## 2. Surfaces (three clients, one backend, no custom API server)
All clients talk **directly to Supabase**. Business logic lives in **RLS + Postgres
RPCs/triggers + 5 Deno Edge Functions**.

- **Flutter app** (`lib/`) — Dart `^3.10.7`, Riverpod, go_router, Freezed, feature-first.
  Android + iOS both first-class. Package id `com.tripsfactory.app`, package name `tripsfactory`.
- **Admin panel** (`admin/`) — Next.js static export + Tailwind, **anon key only**;
  `is_admin()` + RLS is the entire security boundary. Privileged ops via the
  `admin-action` edge function. Deployed to Firebase Hosting.
- **Backend** (`supabase/`) — Postgres + Auth + Storage + Realtime + pg_cron, one baseline
  migration `00000000000000_baseline.sql`. FCM v1 push via a notification-row trigger.
- **Websites** (`public/` → Firebase Hosting) — bilingual (ar-RTL/en) legal + landing,
  `trip.html` deep-link lander, `.well-known/` App Links + Universal Links.

## 3. Core entry points & flows
- **Boot/routing**: `lib/main.dart` → `app_bootstrap.dart` → `app.dart`; router in
  `lib/core/router/app_router.dart`, pure logic in `app_redirect.dart::computeRedirect`
  (splash → appClosed → forceUpdate → onboarding → auth → login-if-logged-out →
  suspended/blocked → home).
- **Trips**: `trips/data/trip_service.dart` → RPC `search_trips_rpc` (server-side,
  paginated) → `Trip.fromJson`. `TripStatus` ↔ `trips_status_check` consistent.
- **Bookings**: `bookings/data/lifecycle/booking_lifecycle_commands.dart` drives the FSM
  (accept/reject/handover/receive/deliver/confirm/payment/cancel) via a handshake helper.
  DB enforces transitions (`enforce_booking_state_machine` + `bookings_status_check`).
  Delivery OTP verified server-side via `verify_delivery_and_complete_booking` RPC.
- **Chat**: booking-scoped over `messages.booking_id` (`chat_service.dart`). Private
  `chat-attachments` bucket; messages store a path/URL, display re-signs via
  `ChatAttachmentUrl.resolve` → `createSignedUrl`. Indexed by `idx_messages_booking_created`.
- **Ratings**: `ratings/data/rating_service.dart`; `role_rated` 'driver'/'client' matches
  `rating_role`; duplicate-guarded by `booking_id`.
- **Notifications**: cross-user sends go through `send_user_notification` RPC; a
  notifications-insert trigger calls the `push-notification` (FCM v1) function, authed by
  `PUSH_WEBHOOK_TOKEN`. Channel `tripsfactory_notification_v1` is consistent app-wide.
- **Auth/roles**: single `profiles.is_admin` flag is the boundary; traveler↔driver is one
  person axis (`is_driver`, `traveler_status`, `traveler_type`).

## 4. White-label seams (keep in sync)
`lib/core/config/`: `brand_config.dart`, `geography_config.dart` (home country AE/ARE),
`localization_config.dart` (ar/en/fr/tr/es; default en), `font_config.dart`,
`domain_config.dart`, theme tokens. `fork.config.json` mirrors `BrandConfig` and is
enforced by `test/config/fork_config_test.dart`. Admin has its own
`geographyConfig.ts`/`localizationConfig.ts` that must match the Flutter seams.

## 5. Verified-healthy (don't chase these)
- All client RPC / edge-function / table / column calls exist with matching signatures
  (incl. `admin_provision_profile(uuid,text,text,boolean)` — old coordination flag resolved).
- Config seams aligned across Flutter ↔ admin (geography, brand ids, schemes, channel).
- `chat_service` using `getPublicUrl` on the private bucket is intentional — it's only a
  path carrier; reads always re-sign.
- No stray shipment/offer/company/account_type references in `lib/` or `admin/src/` source
  or edge functions (only two test-mock leftovers, see below).

---

## 6. OPEN FINDINGS

### Bugs
- **`supabase/functions/send-push-notification/index.ts` used the decommissioned legacy FCM
  API** (`fcm.googleapis.com/fcm/send`, `Authorization: key=...`). **FIXED** — removed the
  dead block and the bogus `fcm_sent`/`fcm_failed` metrics; push is delivered by the
  `notifications` INSERT trigger (`handle_new_notification` → FCM v1 `push-notification`).
  (Note: that function is currently only referenced in a comment by `notification-actions.ts`;
  it's an alternate broadcast path, now correct if wired up.)
- **`public/index.html` had `<h1>TripsFactory TripsFactory</h1>`** (pre-existing duplicate
  brand). **FIXED**.

### Mismatches / inconsistencies
- **`lib/core/enums/app_enums.dart` `BookingStatus` was missing `frozen` and `disputed`**
  (both valid in `bookings_status_check`, rendered by admin `StatusBadge`). With
  `unknownEnumValue: BookingStatus.pending`, those bookings deserialized as "pending" in the
  app. **FIXED** — added both values (+ `@JsonValue`), regenerated `booking_model.g.dart`,
  added `statusFrozen`/`statusDisputed` l10n keys (5 locales) + regenerated, and handled the
  states in all switches (chat enable / image send → disabled; trip-card badge; status text;
  `canTransitionTo` → terminal/admin-managed).
- **Leftover empty admin route dirs**: `admin/src/app/{companies, offers, shipments/[id]}/`.
  **FIXED** — deleted.
- **Pre-existing admin `tsc --noEmit` test-mock errors** (13 errors across
  `AuthGuard.test.tsx`, `audit.test.ts`, `ux-actions.test.ts`, `bookings/page.test.tsx`):
  Supabase `User`/`AuthError`/`UserResponse` mock shapes and a misplaced `findByText`
  `{timeout}` arg. **FIXED** — cast partial mocks `as any`, loosened the range-result state
  type, and moved `timeout` to the 3rd `findByText` arg. `tsc --noEmit` is now fully clean;
  `vitest` 193/193.
- **`send-push-notification` queried the vestigial `user_roles` table** before the
  `profiles.is_admin` fallback. **FIXED** — now authorizes on `profiles.is_admin` only
  (the single security-boundary flag).

### Improvements (small, high-value)
- **Unhandled futures in `AcceptBookingCommand.execute`** (`booking_lifecycle_commands.dart`):
  the three `sendNotificationToUser(...)` calls were not awaited. **FIXED** — wrapped in
  `unawaited(...)` (imported `dart:async`) to document the fire-and-forget intent.

### Release checklist (expected pre-launch gaps — not defects)
- **AASA `appID`** in `public/.well-known/apple-app-site-association` is
  `"TODO: YOUR_TEAM_ID.com.tripsfactory.app"` — fill the Apple Team ID at release (no Apple
  account / app id yet).
- **App Store URL** uses `id000000000` placeholder (`BrandConfig.appStoreUrl`, `trip.html`) —
  no iOS app published yet.
- **`assetlinks.json` SHA256 fingerprint** — **WIPED** (`sha256_cert_fingerprints: []`); the
  stale fingerprint from the previous signing key was removed. Add the new release key's
  fingerprint at signing time.
- **Firebase config files** (`google-services.json`, `GoogleService-Info.plist`) still carry
  the old project ids — replace with the new project's; point `.env` at the new
  Supabase/Firebase projects. `.firebaserc` already uses generic placeholders.
- **DB validation**: run `supabase db reset` against a shadow project to confirm the edited
  baseline applies cleanly.

### Old-backend cleanup (DONE this pass)
Removed every committed reference to the previous Supabase project (`jkeimaazqmsataoeigsf`)
and the previous signing key:
- Baseline `handle_new_notification()` push URL → `<PROJECT_URL>` placeholder (was the old
  project's hardcoded URL); a raw `db reset` is now fail-safe (push no-ops, in-app rows still
  written), and bootstrap still substitutes the real URL at setup. Comment updated.
- Deleted `admin/test_login.js` (stray debug script with the old project URL + a hardcoded
  anon JWT; not referenced by the build).
- Untracked + removed `admin/supabase/.temp/` (old-project CLI link state; root `.gitignore`
  only covered root `supabase/.temp/`) and added `supabase/.temp/` to `admin/.gitignore`;
  removed the now-empty stray `admin/supabase/` dir.
- `git grep` confirms 0 stale `jkeimaazqmsataoeigsf` / old-fingerprint references in tracked files.

---

## 7. Recent security hardening (in baseline, needs shadow-DB validation)
- `messages_insert_not_blocked` made `AS RESTRICTIVE` (fixes message-insert participant bypass).
- `NOT is_user_blocked()` added to `trips_insert` and `bookings_insert`; self-booking guard
  on `bookings_insert` (`requester_id <> trip.traveler_id`).
- `bookings_update` `has_role('support_agent')` → `is_admin()`.
- Admin: removed stale `account_type` from `USER_ORDER_FIELDS`; `isHomeCountryName` aligned
  to exact equality.

## 8. Build / test / verify
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after @freezed/@JsonKey edits
flutter analyze ; flutter test
cd admin ; npm install ; npx tsc --noEmit ; npx vitest run --config vitest.config.mts
```
Don't edit generated files (`*.freezed.dart`, `*.g.dart`, `lib/l10n/generated/**`) — change
source + regenerate. Shell here is PowerShell: use `;` not `&`.
