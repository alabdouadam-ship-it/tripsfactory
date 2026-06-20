# TripsFactory — Logistics & Delivery Marketplace

A production-grade, white-label logistics marketplace: a **Flutter** mobile app,
a **Next.js** admin panel, and a **Supabase** backend. TripsFactory connects
travelers/drivers with senders for shared delivery across cities and borders —
post trips, request deliveries, chat, and manage the whole
lifecycle.

> **Buyer? Start here:** [`docs/GETTING_STARTED.md`](docs/GETTING_STARTED.md) gets
> you from clone to a running app. To rebrand it as your own, see
> [`CORE.md`](CORE.md).

## Highlights

- **Three surfaces, one backend** — Flutter app (iOS/Android), Next.js admin
  console, Supabase (Postgres + Auth + Storage + Realtime + Edge Functions + cron).
- **White-label by design** — brand, 5 languages, themes/fonts, home country
  (ISO), and backend URLs are all configuration seams. One place to change per
  concern; a drift test keeps `fork.config.json` honest.
- **Quality** — **184 Flutter tests + 193 admin tests**, GitHub Actions CI included.
- **0-config backend wiring** — no hardcoded URLs/keys; everything is env-driven.
- **Scripted setup** — `scripts/setup_supabase.*` and `scripts/setup_firebase_hosting.*`
  provision the backend and hosting with minimal manual steps.

## Features

- **Trips** — travelers and drivers post routes with origin, destination, and available capacity.
- **Deliveries** — senders request a delivery on a traveler's or driver's trip.
- **Bookings** — accept requests; track handover, payment, and delivery state.
- **Chat** — direct messaging with text and voice notes.
- **Ratings & reviews**, **reports & blocks**, **ads/promotions**.
- **KYC document verification** with private storage + signed URLs.
- **Push notifications** (FCM v1) for trips, requests, and messages.
- **Realtime** updates, **maps** (Leaflet/OpenStreetMap in admin).
- **Admin panel** — users, drivers, trips, moderation, verification,
  analytics, notifications, settings.
- **Internationalization** — Arabic (RTL), English, French, Turkish, Spanish;
  configurable supported set + default.

## Tech stack & prerequisites

| Tool | Version | For |
|---|---|---|
| Flutter SDK (stable) | bundles **Dart `^3.10.7`** (see `pubspec.yaml`) | mobile app |
| Node.js | 20.x LTS | admin panel (Next.js) |
| Supabase account | — | backend (free tier works for evaluation) |
| Firebase project | — | push notifications + hosting |
| PostgreSQL `psql` | 17 | applying the schema baseline (setup script) |

## Quickstart

```bash
git clone <your-repo-url>
cd tripsfactory
flutter pub get
dart run build_runner build --delete-conflicting-outputs
# configure .env + Firebase config (see docs/GETTING_STARTED.md), then:
flutter run
```

Full steps — backend provisioning, Firebase config, admin panel, deploy — are in
[`docs/GETTING_STARTED.md`](docs/GETTING_STARTED.md).

## Demo mode (no backend needed)

Want to explore the app before provisioning anything? Launch in **demo mode** —
it skips Supabase/Firebase entirely and runs with seeded in-memory data as a
logged-in demo user:

```bash
flutter run --dart-define=DEMO_MODE=true
```

A "DEMO" ribbon appears in the corner. Demo mode is off by default, so normal
builds and tests are unaffected.

## Admin panel

```bash
cd admin
npm install
cp .env.local.example .env.local   # fill in NEXT_PUBLIC_SUPABASE_*
npm run dev                          # http://localhost:3000
```

## Testing

```bash
flutter test                                          # app: 184 tests
cd admin && npx vitest run --config vitest.config.mts # admin: 193 tests
```

## Documentation

Start with **GETTING_STARTED**; everything else is task-specific.

| I want to… | Read |
|---|---|
| Get it running (clone → configure → run → deploy) | [`docs/GETTING_STARTED.md`](docs/GETTING_STARTED.md) |
| Provision the backend (Supabase + Firebase, scripts) | [`docs/BACKEND_SETUP.md`](docs/BACKEND_SETUP.md) |
| Rebrand / make it my own | [`CORE.md`](CORE.md) + [`docs/REBRAND_CHECKLIST.md`](docs/REBRAND_CHECKLIST.md) |
| Understand the system | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) |
| Publish to the app stores | [`docs/STORE_SUBMISSION.md`](docs/STORE_SUBMISSION.md) |
| Run / understand the tests | [`tests/TEST_STRATEGY.md`](tests/TEST_STRATEGY.md) |
| Set support & update terms | [`SUPPORT.md`](SUPPORT.md) |
| Check licenses / version history | [`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md) · [`CHANGELOG.md`](CHANGELOG.md) |
| Orient an AI assistant on this codebase | [`AGENTS.md`](AGENTS.md) |

## License

Commercial single-application license — see [`LICENSE.md`](LICENSE.md). One
purchase = one application. Third-party components are listed in
[`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md).
