-- ============================================================================
-- Promote an EXISTING user to admin (sets profiles.is_admin = true)
-- ============================================================================
-- HOW: edit the email below, then paste this whole script into the
--      Supabase SQL Editor and Run.
--
-- WHY no "disable RLS / disable triggers" dance is needed:
--   * The SQL Editor runs as the `postgres` role, which BYPASSES RLS — so RLS
--     never blocks this. No need to disable/re-enable it.
--   * The admin-column protection triggers (protect_profile_metadata,
--     protect_profile_admin_columns) only block an AUTHENTICATED non-super
--     caller. Here auth.uid() is NULL (postgres), so they pass through.
--     (Verified against the live DB.)
--   * Keeping the triggers enabled means the change is still AUDITED.
--
-- NOTE: this works from the SQL Editor / a privileged DB connection. It is not
--       meant to be run from the app as a logged-in admin (there the triggers
--       would block it by design).
-- ============================================================================

DO $$
DECLARE
  v_email text := 'user@example.com';   -- <<< CHANGE THIS
  v_id    uuid;
  v_was   boolean;
BEGIN
  SELECT id INTO v_id FROM auth.users WHERE lower(email) = lower(trim(v_email));
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'No user found with email %', v_email;
  END IF;

  SELECT is_admin INTO v_was FROM public.profiles WHERE id = v_id;
  IF v_was IS TRUE THEN
    RAISE NOTICE 'User % (%) is already an admin — nothing to do.', v_email, v_id;
    RETURN;
  END IF;

  -- Create the profile row if it somehow doesn't exist, else flip the flag.
  INSERT INTO public.profiles (id, is_admin)
  VALUES (v_id, true)
  ON CONFLICT (id) DO UPDATE SET is_admin = true;

  RAISE NOTICE 'SUCCESS: % (%) is now an admin.', v_email, v_id;

  -- If your environment ever tightens the triggers so the line above is
  -- blocked, uncomment the next line to bypass triggers for THIS transaction
  -- only (auto-resets at COMMIT; note: this also skips the audit trigger):
  --   SET LOCAL session_replication_role = replica;
END $$;

-- Verify (lists all current admins)
SELECT u.email, p.id, p.is_admin, p.full_name
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
WHERE p.is_admin = true
ORDER BY u.email;
