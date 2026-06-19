-- ============================================================================
-- seed.sql — reference location data for a fresh project (run after the schema).
-- Home country: United Arab Emirates (the demo/default country). The 7 emirates
-- are modeled as provinces with their major cities. Bilingual (AR/EN) names;
-- non-Arabic app locales fall back to the English name. Idempotent on id.
--
-- To re-target a fork to another country, replace these rows with that
-- country's locations and update the home-country seam (GeographyConfig /
-- geographyConfig.ts / is_home_country / fork.config.json).
-- ============================================================================
insert into public.locations
  (id, city_name_ar, city_name_en, province_name_ar, province_name_en,
   country_name_ar, country_name_en, country_code, latitude, longitude, is_active)
values
  ('11111111-1111-4111-8111-111111111111','دبي','Dubai','دبي','Dubai','الإمارات العربية المتحدة','United Arab Emirates','AE',25.2048,55.2708,true),
  ('22222222-2222-4222-8222-222222222222','ديرة','Deira','دبي','Dubai','الإمارات العربية المتحدة','United Arab Emirates','AE',25.2719,55.3095,true),
  ('33333333-3333-4333-8333-333333333333','جبل علي','Jebel Ali','دبي','Dubai','الإمارات العربية المتحدة','United Arab Emirates','AE',25.0119,55.1336,true),
  ('44444444-4444-4444-8444-444444444444','أبو ظبي','Abu Dhabi','أبو ظبي','Abu Dhabi','الإمارات العربية المتحدة','United Arab Emirates','AE',24.4539,54.3773,true),
  ('55555555-5555-4555-8555-555555555555','العين','Al Ain','أبو ظبي','Abu Dhabi','الإمارات العربية المتحدة','United Arab Emirates','AE',24.2075,55.7447,true),
  ('66666666-6666-4666-8666-666666666666','مدينة زايد','Madinat Zayed','أبو ظبي','Abu Dhabi','الإمارات العربية المتحدة','United Arab Emirates','AE',23.6839,53.7000,true),
  ('77777777-7777-4777-8777-777777777777','الشارقة','Sharjah','الشارقة','Sharjah','الإمارات العربية المتحدة','United Arab Emirates','AE',25.3463,55.4209,true),
  ('88888888-8888-4888-8888-888888888888','خورفكان','Khor Fakkan','الشارقة','Sharjah','الإمارات العربية المتحدة','United Arab Emirates','AE',25.3393,56.3582,true),
  ('99999999-9999-4999-8999-999999999999','عجمان','Ajman','عجمان','Ajman','الإمارات العربية المتحدة','United Arab Emirates','AE',25.4052,55.5136,true),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','أم القيوين','Umm Al Quwain','أم القيوين','Umm Al Quwain','الإمارات العربية المتحدة','United Arab Emirates','AE',25.5647,55.5552,true),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','رأس الخيمة','Ras Al Khaimah','رأس الخيمة','Ras Al Khaimah','الإمارات العربية المتحدة','United Arab Emirates','AE',25.7895,55.9432,true),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc','الفجيرة','Fujairah','الفجيرة','Fujairah','الإمارات العربية المتحدة','United Arab Emirates','AE',25.1288,56.3265,true),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd','دبا الفجيرة','Dibba Al-Fujairah','الفجيرة','Fujairah','الإمارات العربية المتحدة','United Arab Emirates','AE',25.5925,56.2611,true)
on conflict (id) do nothing;
