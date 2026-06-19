# AGENTS.md — orientation for AI assistants

A concise map for an AI (or new developer) working in this repo. Read this
first; it points to the authoritative docs rather than duplicating them.

## What this is
A logistics marketplace with three surfaces sharing one backend:
- **Flutter app** (`lib/`) — Dart `^3.10.7`, Riverpod, go_router, feature-first.
- **Next.js admin panel** (`admin/`) — static export, Tailwind; anon key + RLS.
- **Supabase backend** (`supabase/`) — Postgres + Auth + Storage + Realtime +
  Edge Functions (Deno) + pg_cron. Firebase is used for FCM push + Hosting.

Architecture + security model: `docs/ARCHITECTURE.md`. Setup: `docs/GETTING_STARTED.md`.
Backend provisioning: `docs/BACKEND_SETUP.md`. White-label seams: `CORE.md`.

## Entry points
- App start: `lib/main.dart` → `lib/app_bootstrap.dart` → `lib/app.dart`.
- Routing/redirects: `lib/core/router/` (pure logic in `app_redirect.dart`).
- Config seams (the white-label surface): `lib/core/config/` —
  `brand_config.dart`, `localization_config.dart`, `geography_config.dart`,
  `font_config.dart`, `domain_config.dart`, `demo_config.dart`, etc.
- Backend schema: single baseline `supabase/migrations/00000000000000_baseline.sql`.

## Build / test / verify
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after editing @freezed models
flutter analyze
flutter test                                                # app suite
cd admin && npm install && npx vitest run --config vitest.config.mts   # admin suite
```
Always run analyze + the relevant test suite before claiming a change is done.

## Conventions / rules
- **Don't edit generated files**: `*.freezed.dart`, `*.g.dart`, `lib/l10n/generated/**`.
  Change the source (`@freezed` model / `.arb`) and regenerate.
- **Config-first**: brand/locale/theme/geography changes go in `lib/core/config/`,
  not scattered in features. `fork.config.json` must stay in sync with the config
  classes — `test/config/fork_config_test.dart` enforces it.
- **Security boundary is the DB**: RLS + `is_admin()` enforce access. The admin
  panel uses the public anon key; privileged ops go through the `admin-action`
  Edge Function. Never embed service-role keys in the app/admin.
- **Secrets**: `.env`, `*firebase-adminsdk*.json`, real `google-services.json` /
  `GoogleService-Info.plist` are gitignored — never commit them.
- **No backend behavior in demo mode**: demo paths are gated behind
  `DemoConfig.enabled` (default false); keep them additive.

## Where to look for X
| Topic | Location |
|---|---|
| Feature code | `lib/features/<feature>/` (data / domain / presentation) |
| Shared services | `lib/core/services/` |
| Models | `lib/features/**/data/*_model.dart`, `lib/core/models/` (freezed) |
| Edge functions | `supabase/functions/` |
| Setup scripts | `scripts/` (`.ps1` + `.sh`; see `docs/BACKEND_SETUP.md` Part D) |
| Tests | `test/` (Flutter), `tests/` (DB/backend); strategy in `tests/TEST_STRATEGY.md` |
