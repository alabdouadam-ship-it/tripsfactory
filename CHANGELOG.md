# Changelog

All notable changes to this product are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this product follows [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

- **MAJOR** — incompatible changes that require buyer action to upgrade
  (schema changes needing migration, breaking config changes).
- **MINOR** — new features, backward-compatible.
- **PATCH** — bug fixes and small improvements, backward-compatible.

The Flutter app version lives in `pubspec.yaml` (`version: MAJOR.MINOR.PATCH+BUILD`).
Keep that in sync with the entries below when you cut a release.

## [Unreleased]

### Added
- **Demo mode** (`--dart-define=DEMO_MODE=true`): launch the app with no backend,
  as a seeded logged-in user with in-memory trips/locations/profile, for instant
  evaluation. Off by default; production builds and tests are unaffected.

### Changed
- **iOS auth compliance**: social sign-in (Google) is now hidden on iOS/macOS by
  default, since Sign in with Apple isn't implemented and App Store Guideline 4.8
  requires it alongside any third-party login. Android shows Google as before.
  Gated by `AuthConfig.appleSignInEnabled` (`lib/core/config/auth_config.dart`) —
  implement Apple Sign-In, then flip it to re-enable Google on iOS. Documented in
  `docs/BACKEND_SETUP.md` (Part C) and `docs/STORE_SUBMISSION.md`.

- Documentation consolidation: merged the backend docs into `docs/BACKEND_SETUP.md`
  (was `SUPABASE_SETUP.md` + `docs/SUPABASE_FIREBASE_SETUP.md`), folded
  `docs/SETUP.md` into `docs/GETTING_STARTED.md`, and merged the four
  `tests/*_TEST_STRATEGY.md` into a single `tests/TEST_STRATEGY.md`. README is now
  a task-routing map. Added a brand-neutral `AGENTS.md` for AI/dev orientation.

- The admin panel now type-checks cleanly; the `tsc --noEmit` CI step is a
  blocking gate (was non-blocking due to pre-existing test-mock type errors).

### Fixed
- **Push (admin broadcast)**: removed a dead code path that called Google's
  decommissioned legacy FCM endpoint (which always failed and reported misleading
  delivery counts). Push is delivered by the notifications trigger via the FCM v1
  `push-notification` function.
- **Booking status**: the app now recognizes the `frozen` and `disputed` booking
  states (admin-managed) and shows them correctly — previously they displayed as
  "Pending". Rendered read-only; the database state machine is unchanged.
- Onboarding "Next/Get Started" button no longer overflows on narrow screens or
  with longer translations (label is now flexible/ellipsized).
- Demo mode is fully offline now: seeded notifications/bookings/deliveries
  and app-config/ads overrides eliminate failed network/realtime calls; FCM init
  is skipped; onboarding is auto-skipped so the demo lands on a populated Home.
- Aligned the support WhatsApp fallback to the UAE number across `BrandConfig`
  and `fork.config.json`.

### Security
- Hardened booking/message Row-Level Security in the schema baseline: message
  inserts are now restricted to booking participants (a non-blocked user can no
  longer write into conversations they aren't part of); blocked users can no
  longer post trips or create bookings; and a user can no longer book their own
  trip. (Apply with `supabase db reset` / the setup script.)

## [1.0.0] — 2026-06-19

### Added
- Initial commercial release: Flutter app, Next.js admin panel, Supabase backend.
- White-label configuration seams: brand, languages (Arabic/English/French/
  Turkish/Spanish), themes + fonts, home country (ISO code), backend URLs —
  with `fork.config.json` and a drift test to keep them in sync.
- Single baseline schema migration (`supabase/migrations/00000000000000_baseline.sql`)
  as the one source of truth, plus scripted setup
  (`scripts/setup_supabase.*`, `scripts/setup_firebase_hosting.*`).
- Decoupled push-notification webhook auth via a dedicated `PUSH_WEBHOOK_TOKEN`.
- Buyer documentation: getting-started quickstart, developer setup, architecture
  overview, rebrand guide, third-party license notices, EULA, and `.example`
  environment/Firebase config templates.

### Notes
- French, Turkish, and Spanish translations are machine-generated — review with
  a native speaker before a production release (see `docs/` translation note).
