# Rebrand Checklist — "Make it yours"

A quick tick-box companion to [`CORE.md`](../CORE.md) (the detailed reference).
Work top to bottom; each item links to the seam that controls it.

## 1. Brand identity (Dart)
- [ ] Edit **`fork.config.json`** with your brand values.
- [ ] Mirror them into **`lib/core/config/brand_config.dart`** (name, URLs, deep-link
      schemes, auth callbacks, store links, support fallback, package id).
- [ ] Run `flutter test` — the drift test (`test/config/fork_config_test.dart`)
      confirms `fork.config.json` and the config classes match.

## 2. Languages
- [ ] Set supported languages + default in **`lib/core/config/localization_config.dart`**
      (`supported`, `defaultLocale`). RTL is auto-detected.
- [ ] Update brand nouns (`appTitle`, etc.) in `lib/l10n/app_*.arb`.
- [ ] If you keep fr/tr/es, have a native speaker review them (machine-generated).

## 3. Themes & fonts
- [ ] Choose supported themes (`AppTheme.supportedThemes`) and default
      (`ThemeNotifier.defaultThemeMode`).
- [ ] Set the font: `BrandConfig.fontFamily`, with optional per-language /
      per-theme overrides in **`lib/core/config/font_config.dart`**.

## 4. Geography (internal vs external routes)
- [ ] Set your home country by **ISO code** in
      **`lib/core/config/geography_config.dart`** (`homeCountryCode`) and whether
      external routes must keep it on one side.
- [ ] Mirror in admin **`admin/src/lib/geographyConfig.ts`** and the
      `is_home_country` function in the SQL baseline.
- [ ] Update the `locations` seed (`supabase/seed.sql`) to your country's data.

## 5. Assets
- [ ] Replace the app icon: `assets/icon/icon.png` → `dart run flutter_launcher_icons`
      (set `adaptive_icon_background` to match). See `docs/GETTING_STARTED.md` §6.1.
- [ ] Replace the admin favicon: `admin/src/app/favicon.ico`.
- [ ] Replace the notification sound (`android/app/src/main/res/raw/`,
      `ios/Runner/`). If changed, use a NEW `notificationChannelId`
      (Android channels are immutable).

## 6. Native identifiers (don't move with Dart constants)
- [ ] Android `applicationId` in `android/app/build.gradle.kts`.
- [ ] Android deep-link schemes / intent filters in `AndroidManifest.xml`.
- [ ] iOS bundle id + URL schemes in `ios/Runner` / `Info.plist`.
- [ ] Signing: `android/key.properties` + keystore (gitignored).

## 7. Backend (your own projects)
- [ ] New **Supabase** project → run `scripts/setup_supabase.{ps1,sh}`; fill
      `.env` and `admin/.env.local`.
- [ ] New **Firebase** project → copy the `.example` config templates to the real
      files; set the FCM service-account + notification-id Edge Function secrets.
- [ ] Wire Hosting sites with `scripts/setup_firebase_hosting.{ps1,sh}` and set
      `BrandConfig.webBaseUrl`.

## 8. Verify
- [ ] `flutter analyze` and `flutter test` (suite green incl. drift test).
- [ ] `dart run build_runner build --delete-conflicting-outputs` if model defaults changed.
- [ ] `cd admin && npx vitest run --config vitest.config.mts`.

## 9. Legal & store
- [ ] Fill `LICENSE.md` placeholders (seller name, jurisdiction, contact, year).
- [ ] Update `docs/PRIVACY_POLICY.md` / `docs/TERMS_OF_SERVICE.md` with your details.
- [ ] Prepare store listings (see `docs/STORE_SUBMISSION.md`).
