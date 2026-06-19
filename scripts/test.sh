#!/usr/bin/env bash
# Run full TripShip test suite: Flutter unit tests + DB tests (if env is set).
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Flutter unit tests ==="
flutter pub get
flutter test test/

if [ -f "tests/db/.env" ]; then
  echo "=== Database tests (tests/db) ==="
  cd tests/db
  npm ci --no-audit --no-fund 2>/dev/null || npm install
  npm run test
  cd "$ROOT"
else
  echo "=== Skipping database tests (no tests/db/.env) ==="
  echo "Copy tests/db/.env.example to tests/db/.env and set Supabase + test user credentials to run DB tests."
fi

if [ -f "tests/backend_tests/.env" ]; then
  echo "=== Backend perf tests (indexes, query budget) ==="
  cd tests/backend_tests
  npm ci --no-audit --no-fund 2>/dev/null || npm install
  npm run test
  cd "$ROOT"
else
  echo "=== Skipping backend perf tests (no tests/backend_tests/.env) ==="
fi

echo "=== All tests finished ==="
