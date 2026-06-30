# TripsFactory — Admin Panel

The web admin console for TripsFactory. A **Next.js (static export)** single-page
app styled with **Tailwind**. It talks **directly to Supabase** using the public
**anon key** — there is no server runtime, no API routes, and no Server Actions.
Access is enforced entirely by Postgres **Row-Level Security** + the `is_admin()`
flag; privileged operations go through the `admin-action` Edge Function.

Manage users, drivers, trips, bookings, moderation, document verification,
reports, reviews, ads, notifications, support, analytics, audit logs, locations,
and a Leaflet/OpenStreetMap map view.

> New here? Start with the repo root [`../docs/GETTING_STARTED.md`](../docs/GETTING_STARTED.md).
> Backend provisioning is in [`../docs/BACKEND_SETUP.md`](../docs/BACKEND_SETUP.md).

## Prerequisites

- Node.js 20 LTS
- A Supabase project (URL + anon key) — see the backend setup guide.

## Setup

```bash
npm install
cp .env.local.example .env.local   # then fill in the two NEXT_PUBLIC_SUPABASE_* values
```

Only the public values are used (RLS is the security boundary — never put the
service-role key here):

```
NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

## Develop

```bash
npm run dev      # http://localhost:3000
```

Sign in with an account whose profile has `is_admin = true`. To promote your
first user, run `scripts/make_user_admin.sql` (repo root) in the Supabase SQL
editor. A non-admin login lands on a "Forbidden" state — that's RLS working.

## Test & type-check

```bash
npm test                 # vitest (193 tests)
npx tsc --noEmit         # type-check
```

## Build & deploy

```bash
npm run build            # static export -> admin/out
./deploy.sh              # build + firebase deploy --only hosting:admin
```

The output in `admin/out` is fully static and can be served by any static host;
the project ships Firebase Hosting wiring (`../firebase.json`,
`../scripts/setup_firebase_hosting.*`).

## Project layout

```
src/
  app/            route pages (one folder per admin section; all 'use client')
    actions/      privileged-op helpers (call the admin-action Edge Function)
  components/     DataTable, Sidebar, AuthGuard, StatusBadge, modals, maps, ...
  lib/            supabase client, i18n, theme, types, geography/localization config
```

`src/lib/geographyConfig.ts` and `src/lib/localizationConfig.ts` mirror the
Flutter app's config seams (`lib/core/config/`) and must stay in sync with them.
