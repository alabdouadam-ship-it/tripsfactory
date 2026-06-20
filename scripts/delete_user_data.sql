-- ============================================================================
-- HARD-DELETE all data for a specific user (IRREVERSIBLE)
-- ============================================================================
-- Run in the Supabase SQL Editor (postgres role).
--
-- SAFETY: this script is DRY-RUN by default — it only prints the counts of what
-- WOULD be deleted. To actually delete, set  v_confirm := true  and re-run.
--
-- It removes everything the user owns or created (trips, bookings,
-- chat messages, ratings, reports, blocks, vehicles, notifications,
-- alerts, support tickets, risk/restriction rows, storage files), nulls the
-- user out as an admin-actor on OTHER users' records (so those records are
-- preserved), then deletes the profile and the auth.users row.
--
-- Mechanism: session_replication_role = replica (transaction-local) disables FK
-- ordering checks + protection/audit triggers for the public-schema deletes, so
-- the order doesn't matter. The auth.users delete runs with FKs back on so the
-- auth.* internal tables cascade correctly.
-- ============================================================================

DO $$
DECLARE
  v_email   text := 'user@example.com';   -- <<< CHANGE THIS
  v_confirm boolean := false;             -- <<< set to TRUE to actually delete
  v_id      uuid;
BEGIN
  SELECT id INTO v_id FROM auth.users WHERE lower(email) = lower(trim(v_email));
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'No user found with email %', v_email;
  END IF;

  ----------------------------------------------------------------------------
  -- DRY RUN: report counts and stop
  ----------------------------------------------------------------------------
  IF NOT v_confirm THEN
    RAISE NOTICE '== DRY RUN for % (%) ==', v_email, v_id;
    RAISE NOTICE 'trips=%  bookings(party)=%',
      (SELECT count(*) FROM trips     WHERE traveler_id = v_id),
      (SELECT count(*) FROM bookings  WHERE requester_id = v_id OR traveler_id = v_id);
    RAISE NOTICE 'messages=%  ratings=%  reports=%  blocks=%  vehicles=%',
      (SELECT count(*) FROM messages WHERE sender_id = v_id),
      (SELECT count(*) FROM ratings  WHERE rater_id = v_id OR rated_id = v_id),
      (SELECT count(*) FROM reports  WHERE reporter_id = v_id OR reported_id = v_id),
      (SELECT count(*) FROM blocks   WHERE blocker_id = v_id OR blocked_id = v_id),
      (SELECT count(*) FROM vehicles WHERE owner_id = v_id);
    RAISE NOTICE 'notifications=%  tokens=%  alerts(route)=%  support_tickets=%',
      (SELECT count(*) FROM notifications      WHERE user_id = v_id),
      (SELECT count(*) FROM notification_tokens WHERE user_id = v_id),
      (SELECT count(*) FROM route_alerts WHERE user_id = v_id),
      (SELECT count(*) FROM support_tickets WHERE user_id = v_id);
    RAISE NOTICE 'storage files=%',
      (SELECT count(*) FROM storage.objects
       WHERE bucket_id IN ('user_documents','chat-attachments','avatars')
         AND (storage.foldername(name))[1] = v_id::text);
    RAISE NOTICE '== Nothing deleted. Set v_confirm := true to delete. ==';
    RETURN;
  END IF;

  ----------------------------------------------------------------------------
  -- REAL DELETE
  ----------------------------------------------------------------------------
  SET LOCAL session_replication_role = replica;  -- FK + triggers off for this tx

  -- Chat / dependent rows that reference the user's bookings/trips
  DELETE FROM messages WHERE sender_id = v_id
     OR booking_id IN (SELECT id FROM bookings WHERE requester_id = v_id OR traveler_id = v_id
                       UNION SELECT id FROM bookings WHERE trip_id IN (SELECT id FROM trips WHERE traveler_id = v_id));

  DELETE FROM delivery_codes
     WHERE booking_id IN (SELECT id FROM bookings WHERE requester_id = v_id OR traveler_id = v_id
                          OR trip_id IN (SELECT id FROM trips WHERE traveler_id = v_id));

  DELETE FROM ratings WHERE rater_id = v_id OR rated_id = v_id;

  -- Other users' interactions with the user's listings, then the listings
  DELETE FROM bookings WHERE requester_id = v_id OR traveler_id = v_id
     OR trip_id IN (SELECT id FROM trips WHERE traveler_id = v_id);
  DELETE FROM trips     WHERE traveler_id = v_id;

  -- Direct user-owned rows
  DELETE FROM vehicles              WHERE owner_id = v_id;
  DELETE FROM notifications         WHERE user_id  = v_id;
  DELETE FROM notification_tokens   WHERE user_id  = v_id;
  DELETE FROM route_alerts          WHERE user_id  = v_id;
  DELETE FROM blocks                WHERE blocker_id = v_id OR blocked_id = v_id;
  DELETE FROM reports               WHERE reporter_id = v_id OR reported_id = v_id;
  DELETE FROM support_messages      WHERE sender_id = v_id;
  DELETE FROM support_tickets       WHERE user_id  = v_id;
  DELETE FROM user_restrictions     WHERE user_id  = v_id OR admin_id = v_id;
  DELETE FROM user_risk_scores      WHERE user_id  = v_id;
  DELETE FROM risk_score_history    WHERE user_id  = v_id;
  DELETE FROM verification_documents WHERE user_id = v_id OR admin_id = v_id;
  DELETE FROM admin_login_events    WHERE admin_id = v_id;
  DELETE FROM saved_filters         WHERE admin_id = v_id;
  DELETE FROM admin_preferences     WHERE admin_id = v_id;
  DELETE FROM export_jobs           WHERE admin_id = v_id;
  DELETE FROM scheduled_notifications WHERE created_by = v_id OR target_user_id = v_id;
  DELETE FROM blacklist             WHERE admin_id = v_id;
  DELETE FROM admin_audit_log       WHERE admin_id = v_id;
  DELETE FROM audit_logs_v2         WHERE admin_id = v_id;

  -- Preserve OTHER users' records where this user was only the admin-actor
  UPDATE profiles  SET suspended_by = NULL          WHERE suspended_by = v_id;
  UPDATE profiles  SET blocked_by = NULL            WHERE blocked_by = v_id;
  UPDATE profiles  SET trust_badge_set_by = NULL    WHERE trust_badge_set_by = v_id;
  UPDATE reports   SET resolved_by = NULL           WHERE resolved_by = v_id;
  UPDATE support_tickets SET resolved_by = NULL     WHERE resolved_by = v_id;

  -- Storage files (documents, chat attachments, avatar)
  DELETE FROM storage.objects
   WHERE bucket_id IN ('user_documents','chat-attachments','avatars')
     AND (storage.foldername(name))[1] = v_id::text;

  -- The profile
  DELETE FROM profiles WHERE id = v_id;

  -- Re-enable FK enforcement so the auth.users delete cascades auth.* internals
  SET LOCAL session_replication_role = DEFAULT;
  DELETE FROM auth.users WHERE id = v_id;

  RAISE NOTICE '== DELETED all data for % (%) ==', v_email, v_id;
END $$;
