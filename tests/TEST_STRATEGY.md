# Automated Test Strategy

This suite proves the security, lifecycle, performance, reliability, and
conversion behavior of the product and prevents regressions. It targets a
logistics/fintech bar: security and lifecycle integrity must not regress. Tests
are **deterministic** and **CI-friendly** (widget/provider/db tests, fake clocks
and clients — no pixel screenshots, no flaky timers).

The work is organized in stages; each stage has its own test folder and budgets.

| Stage | Theme | Flutter tests | Backend tests |
|---|---|---|---|
| 1 | Security lockdown (RLS) | `test/core/router/` | `tests/db/rls.test.ts`, `security-definer.test.ts`, `notification-tokens.test.ts` |
| 2 | Booking lifecycle (FSM) | — | `tests/db/lifecycle-fsm.test.ts`, `concurrency.test.ts`, `delivery-otp.test.ts` |
| 3 | Performance & scale | `test/perf/` | `tests/backend_tests/indexes.test.ts`, `query_budget.test.ts` |
| 4 | Reliability & observability | `test/reliability/` | `tests/backend_tests/idempotency_keys.test.ts` |
| 5 | Conversion optimization | `test/conversion/` | — |

---

## How to run

```bash
# Flutter (all app tests)
flutter pub get
flutter test                      # or a subset: flutter test test/perf/

# Database tests (Stage 1/2)
cd tests/db && npm ci && cp .env.example .env   # set SUPABASE_* + test users
npm run test

# Backend tests (Stage 3/4)
cd tests/backend_tests && npm ci && cp .env.example .env
npm run test

# Everything (Flutter always; DB/backend if their .env exists)
./scripts/test.sh
```

### Required env (database/backend tests)

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (setup/teardown, bypass RLS for seeding) |
| `SUPABASE_ANON_KEY` | Anon key (client-style tests) |
| `TEST_USER_REQUESTER_EMAIL` / `_PASSWORD` | Requester test user |
| `TEST_USER_TRAVELER_EMAIL` / `_PASSWORD` | Traveler test user |
| `TEST_USER_ADMIN_EMAIL` / `_PASSWORD` | Admin test user |

Test users must exist in `auth.users` with matching `public.profiles`. Use
`tests/seed.sql` + `tests/db/setup.ts` or the Supabase Auth UI to create them.

### CI
Both Flutter and DB/backend suites must pass; no business-logic change lands
without corresponding test updates. See `.github/workflows/ci.yml`.

---

## Stage 1 — Security lockdown (RLS)

| Area | What is tested |
|---|---|
| RLS coverage | RLS enabled on `profiles`, `trips`, `bookings`, `messages`, `notifications`, `notification_tokens` |
| Unauthorized read | User A cannot SELECT user B's rows |
| Unauthorized write | User A cannot INSERT/UPDATE/DELETE user B's rows |
| Role restrictions | Traveler/requester/admin-only actions fail for the wrong role |
| Admin-only paths | Only admins touch `user_roles`, `admin_audit_log`, locations, ads, app_config |
| SECURITY DEFINER | `set_user_admin` cannot be executed by non-admin |
| Token uniqueness | `notification_tokens.token` UNIQUE; upsert behavior correct |

Files: `tests/db/rls.test.ts`, `security-definer.test.ts`,
`notification-tokens.test.ts`, and `test/core/router/app_redirect_test.dart`
(redirect: not-logged-in → `/login`, suspended → `/suspended`).

## Stage 2 — Booking lifecycle (FSM)

| Area | What is tested |
|---|---|
| FSM transitions | Allowed transitions succeed; forbidden fail (reject after accepted, cancel after in_transit, completed immutable) |
| Concurrency / race | Concurrent booking acceptance → only one succeeds; no phantom availability |
| Delivery OTP | Code stored; verification enforces booking + role + state |

Files: `tests/db/lifecycle-fsm.test.ts`, `concurrency.test.ts`, `delivery-otp.test.ts`.

## Stage 3 — Performance & scale

Performance **invariants** (deterministic counts/sizes, not timings).

| Area | What is tested |
|---|---|
| Widget rebuilds | Home/TripDetails/Chat stay within rebuild budgets on minor updates |
| Riverpod | `.select()`/split providers don't recompute on unrelated state; ≤1 fetch per lifecycle |
| Pagination | Search uses limit/offset; load-more fetches next page; no full-table scans |
| Backend indexes | All Stage 3 indexes exist (`pg_indexes`) |
| Query/payload | List RPCs return ≤ page size rows |

Budgets live in **`perf_budgets.yaml`** (project root) — tests read it, so tune
limits there without editing tests. Defaults: `default_page_size: 20`,
`max_page_size: 50`, `max_fetch_calls_per_lifecycle: 1`. Prefer tightening over
loosening; commit budget changes with a note.

Files: `test/perf/*` (rebuild_*, riverpod_invalidation, pagination,
network_budget), `test/test_helpers/{rebuild_counter,perf_budgets_loader}.dart`,
`tests/backend_tests/{indexes,query_budget}.test.ts`.

## Stage 4 — Reliability & observability

| Area | What is tested |
|---|---|
| Retry & backoff | SyncWorker retries ≤3; backoff 1s/2s/4s (`1 << attempt`); stops after max |
| Offline queue | FIFO by createdAt; replay removes only on success; partial success retains failed action |
| Idempotency | Same key → single side effect; notifications unique on `idempotency_key` (migration 00009) |
| Error surfacing | Repos return `Result.failure`; no silent swallow |
| Structured logging | Log has level/context/message; error/fatal include error+stack; no PII |
| Crash reporting | Fatal path invokes crash reporter (fake in tests); handled errors don't report fatal |

Determinism via DI: `sleeperForSyncWorkerProvider` (fake sleeper records
durations, no real sleep); `FakeClock`, `FakeLogger`, `FakeCrashReporter`.

Files: `test/reliability/*`, `test/test_helpers/fake_*`,
`tests/backend_tests/idempotency_keys.test.ts`.

## Stage 5 — Conversion optimization

Booking pipeline: Pending → Accepted → (Payment/Handover) → In Transit →
Delivered → Completed. Stepper: Accepted → I Received Goods → Paid → Delivered.

| Area | What is tested |
|---|---|
| Progress indicator | 4-step stepper; current step emphasized; correct order |
| Primary CTA | One primary CTA per state; correct label; secondaries outlined/text |
| State copy | Actionable status text; EN/AR |
| Payment confirmation | Fee/success UI + next-step instruction |
| Review prompt | Completed shows review CTA (`Key('cta_leave_review')`); ≤2 taps |
| Analytics | Funnel events via FakeAnalytics; no duplicates |
| RTL | Arabic: progress order correct; no overflow; CTA discoverable |

Keys: `Key('booking_progress')`, `Key('cta_leave_review')`. Files:
`test/conversion/*`, `test/test_helpers/{booking_fixture,fake_analytics,fake_booking_repo,pump_app}.dart`.

---

## What is NOT tested
- Pixel-perfect / screenshot / visual regression.
- Full end-to-end UI flows against a real backend.
- Load/stress tests or real-device FPS/timing.
- Real third-party delivery (FCM, Sentry, maps) — mocked or out of scope.

## Layout (summary)

```
perf_budgets.yaml                  # Stage 3 budgets (single source of truth)
tests/
  TEST_STRATEGY.md                 # this file
  README.md                        # how to run, env, seed
  seed.sql
  db/                              # Stage 1/2 (Vitest)
  backend_tests/                   # Stage 3/4 (Vitest)
test/
  core/router/                     # Stage 1 redirect guards
  perf/                            # Stage 3
  reliability/                     # Stage 4
  conversion/                      # Stage 5
  test_helpers/                    # fakes & fixtures
scripts/test.sh                    # run all
```
