-- Optional seed for TripShip test suite.
-- Run with Supabase SQL Editor (service role) or: psql $DATABASE_URL -f tests/seed.sql
-- Test users must exist in auth.users (create via Dashboard or Auth API). Profiles are upserted by tests/db/setup.ts.

-- 1) Locations (if your DB has no locations; required for trips/shipments with location FKs)
-- Uncomment and run once; then use the returned id in trip/shipment inserts if needed.
/*
INSERT INTO public.locations (
  country_name_ar, country_name_en, province_name_ar, province_name_en,
  city_name_ar, city_name_en, is_active
) VALUES
  ('السعودية', 'Saudi Arabia', 'الرياض', 'Riyadh', 'الرياض', 'Riyadh', true),
  ('السعودية', 'Saudi Arabia', 'مكة', 'Makkah', 'جدة', 'Jeddah', true)
ON CONFLICT DO NOTHING;
*/

-- 2) App config (optional, for app_config tests)
/*
INSERT INTO public.app_config (key, value) VALUES ('min_version', '1.0.0')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
*/

-- 3) Profiles for test users
-- Do NOT manually insert profiles if you use tests/db/setup.ts: it upserts profiles by email.
-- If you create users manually and want to seed profiles by UUID (e.g. from Auth dashboard):
-- INSERT INTO public.profiles (id, full_name) VALUES
--   ('REQUESTER_UUID', 'Test Requester'),
--   ('TRAVELER_UUID',  'Test Traveler'),
--   ('ADMIN_UUID',     'Test Admin')
-- ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;
