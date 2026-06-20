# Getting Started — Setup & Launch

This guide takes a fresh copy of the project to a running app + admin panel.
It is the **one place to start**; it also covers installing the toolchain from
scratch and common gotchas. Deeper references:

- Backend provisioning (Supabase + Firebase, scripts): `docs/BACKEND_SETUP.md`
- Rebranding / making it your own: `CORE.md` and `docs/REBRAND_CHECKLIST.md`
- Architecture overview: `docs/ARCHITECTURE.md`

---

## 1. Prerequisites

| Tool | Version | For |
|---|---|---|
| Flutter SDK | stable, Dart `^3.10.7` | the mobile app |
| Node.js | 20 LTS | the admin panel (Next.js) |
| Supabase CLI | latest (`npm i -g supabase` or `npx supabase`) | backend provisioning |
| Firebase CLI | latest (`npm i -g firebase-tools` or `npx firebase-tools`) | push + hosting |
| PostgreSQL client `psql` | 17 | applying the DB schema |

You also need free **Supabase** and **Firebase** accounts. macOS + Xcode is only
needed for iOS builds.

### 1.1 Installing the toolchain from scratch (optional)

If nothing is installed yet, install in this order (later tools depend on earlier).

**Windows (winget):**
```powershell
winget install --id Git.Git -e
winget install --id OpenJS.NodeJS.LTS -e        # Node 20 LTS (+ npm)
winget install --id Google.AndroidStudio -e     # Android SDK + emulator
```
Then install the **Flutter SDK** manually: download the Windows zip from
flutter.dev, extract to `C:\src\flutter` (no spaces), add `C:\src\flutter\bin`
to PATH, reopen the terminal, and run `flutter doctor`.

**macOS:**
```bash
brew install --cask flutter android-studio
brew install node
npm install -g firebase-tools         # if deploying
# iOS builds also need Xcode (App Store) + `sudo gem install cocoapods`
```

After installing Flutter: `flutter doctor` (fix what it flags) and
`flutter doctor --android-licenses` (accept the Android SDK licenses). Next.js is
**not** installed separately — `npm install` inside `admin/` pulls it in (step 2).

---

## 2. Install

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Freezed / json_serializable
cd admin && npm install && cd ..
```
(Re-run the `build_runner` line whenever you change a `@freezed` model.)

---

## 3. Firebase config files (required to build) ⚠️

For security, the repo does **not** ship real Firebase config — only templates.
You must provide your own from your Firebase project:

1. Create a Firebase project (see `docs/BACKEND_SETUP.md` Part B).
2. Add an **Android app** (package id `com.tripsfactory.app`, or your own) and download
   **`google-services.json`** → place it at **`android/app/google-services.json`**.
3. Add an **iOS app** (same bundle id) and download **`GoogleService-Info.plist`**
   → place it at **`ios/Runner/GoogleService-Info.plist`**.

Templates showing the exact structure are committed next to each target:
`android/app/google-services.example.json` and
`ios/Runner/GoogleService-Info.example.plist`. The real files are gitignored, so
they never get committed back.

> The Android build fails without `google-services.json`. This is expected — add
> your file first.

---

## 4. Backend (Supabase)

1. Create a Supabase project.
2. Copy the env templates and fill them with your project's URL + anon key
   (Supabase → Settings → API):
   ```bash
   cp .env.example .env
   cp admin/.env.local.example admin/.env.local
   ```
3. Provision the database, storage, functions, cron and secrets in one script
   (full details + the manual dashboard steps are in
   `docs/BACKEND_SETUP.md` Part A):
   ```powershell
   # Windows PowerShell
   $env:SUPABASE_PROJECT_REF='...'; $env:SUPABASE_PROJECT_URL='https://....supabase.co'
   $env:SUPABASE_DB_URL='postgresql://postgres....pooler.supabase.com:5432/postgres'
   $env:SUPABASE_SERVICE_ROLE_KEY='sb_secret_...'
   ./scripts/setup_supabase.ps1
   ```
   ```bash
   # macOS/Linux: same vars with `export`, then:
   ./scripts/setup_supabase.sh
   ```

---

## 5. Run it

```bash
# Mobile app (device/emulator running)
flutter run

# Admin panel (http://localhost:3000)
cd admin && npm run dev
```

Promote your first admin user after signing up once: run
`scripts/make_user_admin.sql` in the Supabase SQL editor (edit the email).

---

## 5b. Evaluate instantly with demo mode (no backend)

Before standing up Supabase/Firebase, you can run the app with seeded mock data:

```bash
flutter run --dart-define=DEMO_MODE=true
```

What it does:
- Skips `.env`, Supabase, and Firebase initialization entirely.
- Logs you in as a seeded **demo user** and lands on Home.
- Serves in-memory demo trips, locations, and profile so you can browse the UI.
- Shows a corner **"DEMO"** ribbon.

Demo mode is a compile-time flag (`DEMO_MODE`, default off via
`bool.fromEnvironment`), so production builds and the test suite are unaffected.
The seam lives in `lib/core/config/demo_config.dart` and `lib/core/demo/`.
Write actions and backend-only features (push, chat, real listings) are
no-ops/empty in demo — it's for evaluation, not production.

---

## 6. Make it yours (rebrand)

Everything brand/domain-specific lives in configuration seams — no feature-code
hunting. The full checklist is in **`CORE.md`**; the highlights:

- **Brand**: `lib/core/config/brand_config.dart` (+ keep `fork.config.json` in sync — a test enforces it).
- **Languages**: `lib/core/config/localization_config.dart` (supported + default).
- **Themes / fonts**: `AppTheme.supportedThemes` / `ThemeNotifier.defaultThemeMode` + `lib/core/config/font_config.dart`.
- **Home country (internal/external routes)**: `lib/core/config/geography_config.dart` (ISO code) + admin `admin/src/lib/geographyConfig.ts` + `is_home_country` in the SQL baseline.
- **Native ids / icons**: package id, bundle id, deep-link schemes, launcher icon (see `CORE.md` Phase C).

### 6.1 Replace the app icon

The app uses the `flutter_launcher_icons` generator (config is inline in
`pubspec.yaml` under `flutter_launcher_icons:`), so swapping the icon is a
one-file change plus one command.

**Need a new icon?** Hand this prompt to an image generator:

> A modern, minimal mobile app icon for a logistics and parcel-delivery
> marketplace. A single bold geometric symbol combining a parcel/delivery box
> with a directional arrow or route path, suggesting movement and delivery.
> Flat vector style, clean lines, no text or letters. Centered symbol with
> generous padding. Solid or subtle two-tone background. Professional,
> trustworthy palette. Crisp at very small sizes. Square 1024×1024 px, no
> heavy gradients, no drop shadows.

Guidance for the source image:
- **1024×1024 PNG**, square (the OS adds rounded corners — don't bake them in).
- Keep the meaningful content inside the **center ~66%**; Android's adaptive
  icon crops the edges with circle/squircle masks.
- Avoid thin lines or text that disappear at 48 px.

Steps:
1. Overwrite `assets/icon/icon.png` with your new 1024×1024 image.
2. In `pubspec.yaml`, set `adaptive_icon_background:` to a hex color matching
   your icon's background (default is the old `#5D2E0C`).
3. Regenerate platform icons: `dart run flutter_launcher_icons`
4. Rebuild: `flutter clean && flutter run` (or a full build).
5. **Admin favicon** (separate): replace `admin/src/app/favicon.ico` with a
   32×32 / 48×48 `.ico` export of the same icon.

---

## 7. Deploy

- **Hosting sites** (admin + legal): `./scripts/setup_firebase_hosting.ps1` (interactive — creates/wires the two sites).
- **Admin panel**: `cd admin && ./deploy.sh` (build + `firebase deploy --only hosting:admin`).
- **Legal pages**: `firebase deploy --only hosting:legal`.
- **Mobile app**: `flutter build appbundle` / `flutter build ios` and submit to the stores.

---

## 8. Verify / troubleshoot

- Tests: `flutter test` (app) and `cd admin && npx vitest run --config vitest.config.mts` (admin).
- **Android build fails / google-services missing** → you skipped step 3.
- **App crashes on launch with a dotenv error** → you didn't create `.env` (step 4), or run in demo mode (§5b).
- **App loads but no data / auth errors** → `.env` / `admin/.env.local` not filled, or the Supabase project URL/anon key is wrong.
- **`build_runner` conflicts** → re-run with `--delete-conflicting-outputs`.
- **2 widget tests fail on `ink_sparkle.frag`** → `flutter precache --universal --force`.
- **Admin "Forbidden" after login** → that account isn't an admin; run `scripts/make_user_admin.sql`.
- **Push notifications don't arrive** → check the `PUSH_WEBHOOK_TOKEN` + `FIREBASE_SERVICE_ACCOUNT` secrets and the edge function logs (`docs/BACKEND_SETUP.md` Part B / troubleshooting note).
- **Google sign-in fails** → the Google OAuth client + Supabase provider + redirect URLs (`docs/BACKEND_SETUP.md` Part C). Automatable via `scripts/setup_google_auth.*`.
