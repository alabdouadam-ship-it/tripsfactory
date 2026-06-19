# CORE — White-Label Fork Guide

This project is a **white-label core**: a verified, geo/route-based two-sided
marketplace engine (post → match → negotiate in chat → dual-confirmation
handshake + OTP → rate, with role/KYC tiers, moderation, notifications, and an
admin console). Each product is a **fork** of this core, specialized to a brand
and domain.

This document describes what is shared, what each fork overrides, the fork
procedure, and how to pull core improvements into existing forks.

---

## 1. The configuration seams

A fork should only need to touch these. They were extracted so re-branding and
re-orienting don't require hunting through feature code.

| Seam | File | Purpose |
|------|------|---------|
| **BrandConfig** | `lib/core/config/brand_config.dart` | Non-localized brand identity: name, deep-link schemes, auth callbacks, web/legal URL, store links, package id, notification channel/sound, support fallback, font, logo asset. |
| **DomainConfig** | `lib/core/config/domain_config.dart` | Canonical marketplace vocabulary (account types, verification statuses, traveler/identity types, roles) — the persisted Supabase contract values. |
| **StorageBuckets** | `lib/core/config/storage_buckets.dart` | Supabase Storage bucket names. |
| **RegistrationRequirements** | `lib/core/config/registration_requirements.dart` | Which documents each role must provide to apply. |
| **LocalizationConfig** | `lib/core/config/localization_config.dart` | Which languages the app ships (`supported`), the first-launch `defaultLocale`, and RTL detection. Currently: ar, en, fr, tr, es. |
| **FontConfig** | `lib/core/config/font_config.dart` | Font family resolution: global default (`BrandConfig.fontFamily`) with optional per-language and per-theme overrides. |
| **GeographyConfig** | `lib/core/config/geography_config.dart` | Home country for the internal/external route split: matched primarily by **ISO `country_code`** (`homeCountryCode`), with name (en/ar) as fallback; plus whether external routes must keep the home country on one side. |
| **Theme / tokens** | `lib/core/theme/app_theme.dart`, `tripship_design_tokens.dart` | The theme registry + which themes a fork offers (`AppTheme.supportedThemes`), default theme (`ThemeNotifier.defaultThemeMode`), and per-call font (`AppTheme.getTheme(mode, fontFamily:)`). |
| **Copy** | `lib/l10n/app_en.arb`, `app_ar.arb`, `app_fr.arb`, `app_tr.arb`, `app_es.arb` | All user-facing text, including brand/domain nouns (`appTitle`, etc.). Non-template locales fall back to English for untranslated keys. |
| **Runtime config** | `app_settings` table / `AppConfigService` | Admin-tunable values (support number, banners, force-update, popups). |

**Rule of thumb:**
- Identity that never changes at runtime → `BrandConfig`.
- User-facing copy → ARB.
- Admin-tunable at runtime → `app_settings`.
- Persisted domain contract values → `DomainConfig` (coordinate with the DB).

`fork.config.json` is a single descriptor of a fork's brand identity. The test
`test/config/fork_config_test.dart` enforces that its `brand`, `localization`,
`theme`, `font` and `geography` blocks match `BrandConfig`, `LocalizationConfig`,
`AppTheme`/`ThemeNotifier`, `FontConfig` and `GeographyConfig`, so the JSON stays
an accurate, reviewable summary of the fork.

---

## 2. Shared vs per-fork

**Shared (inherit from core, avoid forking):**
- All feature logic under `lib/features/**`, core services, router/redirect.
- The Supabase schema baseline: migrations, RLS, RPCs, triggers, FSMs.
- The admin panel (`admin/`) structure.
- Test suite.

**Per-fork (must override):**
- `BrandConfig` values (+ keep `fork.config.json` in sync).
- Brand assets: launcher icon, splash logo, notification sound.
- Native identifiers (package/bundle id, deep-link schemes, OAuth redirect).
- A dedicated **Supabase project** and **Firebase project** (URLs, keys, FCM
  sender, service account, `google-services.json` / `GoogleService-Info.plist`).
- `DomainConfig` / `RegistrationRequirements` only when re-orienting the domain.
- ARB copy for brand/domain nouns.

---

## 3. Fork procedure

### Phase A — App-layer brand (Dart, low risk)
1. Clone the core into a new repo.
2. Edit `fork.config.json` with the new brand values.
3. Mirror those values into `BrandConfig` (run the suite — the drift test will
   confirm they match).
4. Set the default theme (`ThemeNotifier.defaultThemeMode`), the offered theme
   set (`AppTheme.supportedThemes`), the languages (`LocalizationConfig.supported`
   / `defaultLocale`) and font (`BrandConfig.fontFamily`, or per-language /
   per-theme overrides in `FontConfig`).
5. Replace brand assets in `assets/icon/` and the notification sounds
   (`android/app/src/main/res/raw/`, `ios/Runner/`). If the notification sound
   changes, use a NEW `notificationChannelId` (Android channels are immutable).
6. Update ARB `appTitle` and any brand/domain nouns.

### Phase B — Backend (per-instance)
7. Create a new Supabase project; apply the migration baseline; set
   `SUPABASE_URL` / `SUPABASE_ANON_KEY` in `.env`.
8. Create a new Firebase project; add `google-services.json` and
   `GoogleService-Info.plist`; upload the Firebase service account secret and
   the FCM config to the Supabase Edge Function secrets.
9. Edge functions read brand notification ids from env with safe fallbacks
   (`NOTIFICATION_CHANNEL_ID`, `NOTIFICATION_SOUND_ANDROID`,
   `NOTIFICATION_SOUND_IOS`); set these to match `BrandConfig`.

### Phase C — Native (does NOT move with Dart constants)
10. Android `applicationId` in `android/app/build.gradle.kts`.
11. Android deep-link schemes/intent filters in `AndroidManifest.xml`.
12. iOS bundle id and URL schemes in `ios/Runner` / `Info.plist`.
13. Launcher icons via `flutter_launcher_icons.yaml` (run the generator).
14. Signing keys (`android/key.properties`, gitignored).

### Phase D — Verify
15. `flutter analyze` and `flutter test` (suite green, incl. the fork drift test).
16. If model defaults changed, run `dart run build_runner build --delete-conflicting-outputs`.
17. `cd admin && npx tsc --noEmit && npx vitest run --config vitest.config.mts`.

---

## 4. Domain re-orientation (when the fork is a different product)

The core models "post A→B with capacity, match, handshake-complete, rate."
- **Closest fits (low effort):** ride-share / carpooling, on-demand courier.
- **Medium (drop the route dimension):** home/at-home services, equipment
  rental, tutoring/local gigs.
- **High effort:** anything needing in-app payments or live GPS tracking (the
  core deliberately has neither; completion is a manual/OTP handshake).

Re-orienting changes:
- `DomainConfig` vocabulary + ARB nouns + icons (app layer).
- `RegistrationRequirements` (what each role must provide).
- **Backend FSMs and RLS** — these are DB-enforced and adapted per domain; they
  are NOT config. Treat the core schema as a documented baseline to evolve.

---

## 5. Upgrade path (pulling core changes into a fork)

- Keep forks as git remotes of the core; merge/rebase core changes periodically.
- Conflicts should concentrate in the seam files (`BrandConfig`, assets, native
  config, ARB) — feature code merges cleanly if forks avoid editing it.
- After merging: regenerate code if models changed, then run analyze + tests.

---

## 6. Status of the core-ification work

- **Phase 1 — Brand identity:** `BrandConfig` + wired consumers. ✅
- **Phase 2 — Backend wiring:** `StorageBuckets`; edge-function notification ids
  env-driven with fallbacks. ✅ (edge functions pending a Deno runtime check)
- **Phase 4 — Domain vocabulary:** `DomainConfig` (data + presentation +
  generated defaults) and `RegistrationRequirements`. ✅
- **Phase 5 — Fork tooling:** `fork.config.json` + drift test + this guide. ✅
- **Phase 3 — Native parameterization:** documented checklist above; per-fork.
