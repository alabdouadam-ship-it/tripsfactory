# TripShip Test Suite

Runbook for Stage 1 (Security Lockdown) and Stage 2 (Booking Lifecycle) tests.

## Prerequisites

- **Database tests:** Node.js 18+, Supabase project (local or hosted).
- **Flutter tests:** Flutter SDK; run `flutter pub get` at project root.
- **Env:** Copy `tests/db/.env.example` to `tests/db/.env` and set variables (see below).

## Required env vars (database tests)

Create `tests/db/.env` from `tests/db/.env.example`:

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Supabase project URL (e.g. `https://xxx.supabase.co`). |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (setup/teardown and bypass RLS). |
| `SUPABASE_ANON_KEY` | Anon key (optional; used for client-style checks). |
| `TEST_USER_REQUESTER_EMAIL` | Requester test user email. |
| `TEST_USER_REQUESTER_PASSWORD` | Requester test user password. |
| `TEST_USER_TRAVELER_EMAIL` | Traveler test user email. |
| `TEST_USER_TRAVELER_PASSWORD` | Traveler test user password. |
| `TEST_USER_ADMIN_EMAIL` | Admin test user email. |
| `TEST_USER_ADMIN_PASSWORD` | Admin test user password. |

Test users must exist in **Supabase Auth** and have **profiles** in `public.profiles`. The runner will ensure profiles exist (upsert by email) when using the service role; you still need to create the three Auth users (Dashboard → Authentication → Add user, or sign up once).

For **admin**, the test setup grants the admin role via direct `user_roles` insert (service role) so `set_user_admin` behavior can be tested separately.

## Running tests

### 1. Database tests (Stage 1 + Stage 2)

```bash
cd tests/db
npm ci
cp .env.example .env   # edit with your Supabase and test user credentials
npm run test
```

### 2. Flutter unit tests

From **project root**:

```bash
flutter pub get
flutter test test/
```

### 3. All tests (script)

From **project root**:

```bash
./scripts/test.sh
# or on Windows: bash scripts/test.sh
```

## Supabase local

```bash
supabase start
# Apply migrations (default with supabase start)
# Create test users (Auth UI or CLI), then set SUPABASE_URL to local URL and keys in tests/db/.env
cd tests/db && npm run test
```

## Seed data

- `tests/seed.sql`: Optional. Use to insert **locations** (and other reference data) if your project has no data. Test users and profiles are created/ensured by the Node setup via Auth and service-role upserts; you do not need to edit UUIDs in seed.sql for users.
- To add a default location for tests, run the first block of `seed.sql` (locations) with the Supabase SQL editor (service role) so trip inserts can reference valid location IDs if needed.

## Stage 4 reliability regression tests

- **Flutter:** `flutter test test/reliability/` (retry/backoff, offline queue, idempotency, error surfacing, logging/crash reporter, analytics placeholder).
- **Backend:** Same as Stage 3 backend; `tests/backend_tests/idempotency_keys.test.ts` verifies notifications idempotency_key unique constraint.
- See **tests/TEST_STRATEGY.md** (Stage 4) for strategy and policies.

## Stage 3 performance regression tests

- **Flutter perf:** `flutter test test/perf/` (rebuild budgets, Riverpod, pagination, network budgets). Budgets are in `perf_budgets.yaml` at project root.
- **Backend perf:** `cd tests/backend_tests && cp .env.example .env` (set `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`), then `npm ci && npm run test` (index existence, query row limits). Requires migration `00010_get_public_index_names_rpc.sql` applied.
- See **tests/TEST_STRATEGY.md** (Stage 3) for full strategy and how to update budgets.

## CI

- Set the same env vars in your CI environment.
- Database: `cd tests/db && npm ci && npm run test`.
- Flutter: `flutter pub get && flutter test test/` (includes `test/perf/`).
- Backend perf: `cd tests/backend_tests && npm ci && npm run test` (if .env present).
- Both must pass.
