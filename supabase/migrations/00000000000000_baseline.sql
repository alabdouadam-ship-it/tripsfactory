-- ============================================================================
-- 00000000000000_baseline.sql — COMPLETE database schema (single source of truth).
--
-- The one and only schema definition: required Postgres extensions followed by
-- all tables, enums, functions, triggers, RLS policies and indexes. Applied to a
-- FRESH (empty) project by scripts/setup_supabase.* (which runs every file in
-- supabase/migrations/ in order). Not idempotent (plain CREATE) — runs once on
-- an empty DB.
--
-- Post-schema, project-specific steps (storage buckets, cron, realtime, the push
-- webhook URL, storage policies, reference seed) are applied separately by the
-- setup script via bootstrap.sql / storage_policies.sql / seed.sql.
--
-- To evolve the schema, add new timestamped migration files alongside this one.
-- ============================================================================

-- ============================================================================
-- Required Postgres extensions (must be created before the schema below, which
-- uses pg_trgm gin_trgm_ops indexes and extensions.gen_random_bytes).
-- Schemas mirror the source project (pg_trgm/postgis/pg_net in public; pgcrypto
-- /uuid-ossp in extensions). If any CREATE fails on your plan, enable it via
-- Dashboard → Database → Extensions, then re-run.
-- ============================================================================
create schema if not exists extensions;

create extension if not exists pgcrypto      with schema extensions;
create extension if not exists "uuid-ossp"   with schema extensions;
create extension if not exists pg_trgm        with schema public;
create extension if not exists postgis        with schema public;
create extension if not exists pg_net         with schema public;

-- Usually pre-enabled / managed by Supabase; included for completeness.
create extension if not exists pg_cron;
create extension if not exists supabase_vault;
create extension if not exists pg_stat_statements with schema extensions;


--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.5

-- Started on 2026-06-18 22:13:58

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 14 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS public;


--
-- TOC entry 5649 (class 0 OID 0)
-- Dependencies: 14
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 2279 (class 1247 OID 52391)
-- Name: admin_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.admin_role AS ENUM (
    'super_admin',
    'ops_admin',
    'finance_admin',
    'support_agent',
    'read_only_observer'
);


--
-- TOC entry 2216 (class 1247 OID 39331)
-- Name: app_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.app_role AS ENUM (
    'super_admin',
    'admin',
    'moderator',
    'traveler_with_car',
    'traveler_no_car',
    'sender',
    'suspended',
    'banned'
);


--
-- TOC entry 2285 (class 1247 OID 52463)
-- Name: dispute_outcome; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.dispute_outcome AS ENUM (
    'favour_requester',
    'favour_traveler',
    'invalid_claim',
    'mutually_resolved'
);


--
-- TOC entry 2190 (class 1247 OID 19025)
-- Name: rating_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.rating_role AS ENUM (
    'driver',
    'client'
);


--
-- TOC entry 1027 (class 1255 OID 92864)
-- Name: admin_daily_trip_count(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_daily_trip_count(p_days integer DEFAULT 30) RETURNS TABLE(day date, trip_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  RETURN QUERY
  SELECT (t.created_at AT TIME ZONE 'UTC')::date AS day, COUNT(*)::bigint AS trip_count
  FROM public.trips t
  WHERE t.created_at >= now() - make_interval(days => GREATEST(COALESCE(p_days, 30), 1))
  GROUP BY (t.created_at AT TIME ZONE 'UTC')::date
  ORDER BY 1;
END;
$$;


--
-- TOC entry 1360 (class 1255 OID 52461)
-- Name: admin_force_status_transition(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_force_status_transition(p_booking_id uuid, p_new_status text, p_reason text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NOT public.has_role('ops_admin') THEN
    RAISE EXCEPTION 'Forbidden: ops_admin or higher required to force booking status transitions.';
  END IF;

  -- Bypass the FSM guard by directly updating the row; the universal audit
  -- trigger (00012) records the change.
  UPDATE public.bookings
  SET
    status = p_new_status,
    internal_notes = COALESCE(internal_notes, '')
                     || E'\n[FORCE_STATUS] '
                     || p_new_status
                     || ': '
                     || COALESCE(p_reason, ''),
    dispute_resolved_at = CASE WHEN p_new_status IN ('completed', 'cancelled') THEN now() ELSE dispute_resolved_at END,
    dispute_resolved_by = CASE WHEN p_new_status IN ('completed', 'cancelled') THEN auth.uid() ELSE dispute_resolved_by END
  WHERE id = p_booking_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking % not found', p_booking_id;
  END IF;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 400 (class 1259 OID 18839)
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    phone_number text,
    full_name text,
    avatar_url text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    bio text,
    is_available boolean DEFAULT false,
    traveler_status text DEFAULT 'none'::text,
    traveler_license_url text,
    traveler_rating_avg numeric(3,2) DEFAULT 0.0,
    traveler_rating_count integer DEFAULT 0,
    client_rating_avg numeric(3,2) DEFAULT 0.0,
    client_rating_count integer DEFAULT 0,
    is_admin boolean DEFAULT false,
    traveler_type text,
    identity_type text,
    identity_doc_url text,
    rental_contract_url text,
    is_suspended boolean DEFAULT false,
    subscription_expires_at timestamp with time zone,
    license_expires_at timestamp with time zone,
    is_driver boolean DEFAULT false,
    driver_validity_date timestamp with time zone,
    avatar_updated_at timestamp with time zone,
    identity_doc_url_pending text,
    traveler_license_url_pending text,
    rental_contract_url_pending text,
    suspension_reason text,
    suspended_at timestamp with time zone,
    suspended_by uuid,
    deleted_at timestamp with time zone,
    is_frozen boolean DEFAULT false,
    strike_count integer DEFAULT 0,
    internal_notes text,
    identity_number text,
    identity_expiry timestamp with time zone,
    is_verified_enterprise boolean DEFAULT false,
    is_blocked boolean DEFAULT false,
    promoted_until timestamp with time zone,
    blocked_reason text,
    blocked_at timestamp with time zone,
    blocked_by uuid,
    is_trusted boolean DEFAULT false NOT NULL,
    is_featured boolean DEFAULT false NOT NULL,
    trust_badge text,
    trust_badge_set_at timestamp with time zone,
    trust_badge_set_by uuid,
    CONSTRAINT profiles_traveler_status_check CHECK ((traveler_status = ANY (ARRAY['none'::text, 'pending'::text, 'approved'::text, 'rejected'::text, 'suspended'::text, 'blocked'::text])))
);


--
-- TOC entry 5650 (class 0 OID 0)
-- Dependencies: 400
-- Name: COLUMN profiles.traveler_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.traveler_status IS 'Status of the driver application: none, pending, approved, rejected';


--
-- TOC entry 5654 (class 0 OID 0)
-- Dependencies: 400
-- Name: COLUMN profiles.driver_validity_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.driver_validity_date IS 'Expiration date for driver privileges';


--
-- TOC entry 5655 (class 0 OID 0)
-- Dependencies: 400
-- Name: COLUMN profiles.is_blocked; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.is_blocked IS 'Hard block: account cannot log in / use the app. Independent of is_suspended.';


--
-- TOC entry 5656 (class 0 OID 0)
-- Dependencies: 400
-- Name: COLUMN profiles.is_trusted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.is_trusted IS 'Marks profile as a trusted account (driver). Use trust_badge for label.';


--
-- TOC entry 5657 (class 0 OID 0)
-- Dependencies: 400
-- Name: COLUMN profiles.is_featured; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profiles.is_featured IS 'Marks profile as featured (e.g. featured driver on home).';


--
-- TOC entry 650 (class 1255 OID 92860)
-- Name: admin_provision_profile(uuid, text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_provision_profile(p_user_id uuid, p_full_name text, p_phone text, p_make_driver boolean DEFAULT false) RETURNS public.profiles
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
INSERT INTO public.profiles (
  id,
  full_name,
  phone_number,
  traveler_status,
  is_driver,
  traveler_type
)
VALUES (
  p_user_id,
  p_full_name,
  p_phone,
  CASE WHEN p_make_driver THEN 'pending' ELSE 'none' END,
  p_make_driver,
  CASE WHEN p_make_driver THEN 'with_vehicle' ELSE 'no_vehicle' END
)
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  phone_number = COALESCE(EXCLUDED.phone_number, public.profiles.phone_number),
  traveler_status = CASE
    WHEN p_make_driver THEN
      CASE
        WHEN public.profiles.traveler_status IN ('approved', 'blocked', 'rejected')
          THEN public.profiles.traveler_status
        ELSE 'pending'
    END
    ELSE public.profiles.traveler_status
  END,
  is_driver = CASE
    WHEN p_make_driver THEN true
    ELSE public.profiles.is_driver
  END,
  traveler_type = CASE
    WHEN p_make_driver THEN 'with_vehicle'
    ELSE public.profiles.traveler_type
  END
RETURNING *;
$$;


--
-- TOC entry 5658 (class 0 OID 0)
-- Dependencies: 650
-- Name: FUNCTION admin_provision_profile(p_user_id uuid, p_full_name text, p_phone text, p_make_driver boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.admin_provision_profile(p_user_id uuid, p_full_name text, p_phone text, p_make_driver boolean) IS 'Provision or update a profile row for a newly-created auth user (service_role only).';


--
-- TOC entry 1097 (class 1255 OID 92862)
-- Name: admin_top_destinations(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_top_destinations(p_days integer DEFAULT 30, p_limit integer DEFAULT 10) RETURNS TABLE(city_en text, city_ar text, total_trips bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  RETURN QUERY
  SELECT l.city_name_en, l.city_name_ar, COUNT(*)::bigint AS total_trips
  FROM public.trips t
  JOIN public.locations l ON l.id = t.dest_location_id
  WHERE t.created_at >= now() - make_interval(days => GREATEST(COALESCE(p_days, 30), 1))
  GROUP BY l.city_name_en, l.city_name_ar
  ORDER BY COUNT(*) DESC
  LIMIT GREATEST(COALESCE(p_limit, 10), 0);
END;
$$;


--
-- TOC entry 1273 (class 1255 OID 92861)
-- Name: admin_top_origin_cities(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_top_origin_cities(p_days integer DEFAULT 30, p_limit integer DEFAULT 10) RETURNS TABLE(city_en text, city_ar text, total_trips bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  RETURN QUERY
  SELECT l.city_name_en, l.city_name_ar, COUNT(*)::bigint AS total_trips
  FROM public.trips t
  JOIN public.locations l ON l.id = t.origin_location_id
  WHERE t.created_at >= now() - make_interval(days => GREATEST(COALESCE(p_days, 30), 1))
  GROUP BY l.city_name_en, l.city_name_ar
  ORDER BY COUNT(*) DESC
  LIMIT GREATEST(COALESCE(p_limit, 10), 0);
END;
$$;


--
-- TOC entry 1275 (class 1255 OID 92863)
-- Name: admin_user_type_distribution(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_user_type_distribution() RETURNS TABLE(user_type text, total bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  RETURN QUERY
  WITH classified AS (
    SELECT
      CASE
        WHEN COALESCE(p.traveler_status, 'none') <> 'none'
          AND COALESCE(p.is_driver, false) = true THEN 'driver'
        WHEN COALESCE(p.traveler_status, 'none') <> 'none' THEN 'traveler'
        ELSE 'individual'
      END AS bucket
    FROM public.profiles p
  ),
  expected(bucket_name, sort_order) AS (
    VALUES
      ('driver'::text, 1),
      ('traveler'::text, 2),
      ('individual'::text, 4)
  )
  SELECT expected.bucket_name, COUNT(classified.bucket)::bigint AS total
  FROM expected
  LEFT JOIN classified ON classified.bucket = expected.bucket_name
  GROUP BY expected.bucket_name, expected.sort_order
  ORDER BY expected.sort_order;
END;
$$;


--
-- TOC entry 977 (class 1255 OID 94388)
-- Name: can_read_chat_attachment(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.can_read_chat_attachment(object_name text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.messages m
    JOIN public.bookings b ON b.id = m.booking_id
    WHERE m.content LIKE '%' || object_name
      AND (
        b.requester_id = auth.uid()
        OR b.traveler_id = auth.uid()
      )
  );
$$;


--
-- TOC entry 658 (class 1255 OID 58787)
-- Name: cancel_trip(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cancel_trip(p_trip_id uuid, p_user_id uuid DEFAULT NULL::uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_owner uuid;
  v_actor uuid := auth.uid();
  v_is_admin boolean := public.is_admin();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;

  SELECT traveler_id INTO v_owner
  FROM public.trips
  WHERE id = p_trip_id
  FOR UPDATE;

  IF v_owner IS NULL THEN
    RAISE EXCEPTION 'TRIP_NOT_FOUND';
  END IF;

  -- Authorization: trip owner or admin only.
  IF v_actor <> v_owner AND NOT v_is_admin THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;

  -- Active-booking guard applies to the owner; admins override it.
  IF NOT v_is_admin THEN
    IF EXISTS (
      SELECT 1 FROM public.bookings
      WHERE trip_id = p_trip_id
        AND (status IN ('in_transit', 'delivered', 'completed')
             OR goods_received_by_traveler_at IS NOT NULL
             OR goods_received_by_client_at IS NOT NULL
             OR payment_confirmed_by_traveler_at IS NOT NULL)
    ) THEN
      RAISE EXCEPTION 'Cannot cancel: active bookings with goods/payment';
    END IF;
  END IF;

  UPDATE public.trips
  SET status = 'cancelled'
  WHERE id = p_trip_id;

  UPDATE public.bookings
  SET status = 'rejected'
  WHERE trip_id = p_trip_id
    AND status IN ('pending', 'in_communication');
END;
$$;


--
-- TOC entry 695 (class 1255 OID 52602)
-- Name: check_role(public.admin_role[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_role(required_roles public.admin_role[]) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT public.is_admin();
$$;


--
-- TOC entry 660 (class 1255 OID 18967)
-- Name: check_user_exists(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_user_exists(email_input text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = email_input) THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$;


--
-- TOC entry 846 (class 1255 OID 52601)
-- Name: check_user_expiry_suspension(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_user_expiry_suspension() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Suspend users with expired identity
    UPDATE public.profiles
    SET is_suspended = true,
        internal_notes = COALESCE(internal_notes, '') || ' [Auto-Suspension] Identity Expired.'
    WHERE 
        identity_expiry < NOW() 
        AND is_suspended = false
        AND traveler_status = 'approved';
END;
$$;


--
-- TOC entry 1389 (class 1255 OID 52309)
-- Name: enforce_booking_state_machine(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_booking_state_machine() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF auth.uid() IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  IF NOT (
       (OLD.status = 'in_communication' AND NEW.status IN ('pending', 'cancelled', 'rejected'))
    OR (OLD.status = 'pending'          AND NEW.status IN ('accepted', 'rejected', 'cancelled'))
    OR (OLD.status = 'accepted'         AND NEW.status IN ('in_transit', 'cancelled'))
    OR (OLD.status = 'in_transit'       AND NEW.status IN ('delivered', 'completed'))
    OR (OLD.status = 'delivered'        AND NEW.status = 'completed')
  ) THEN
    RAISE EXCEPTION 'ILLEGAL_TRANSITION: booking % -> %', OLD.status, NEW.status;
  END IF;

  -- A status that asserts physical progress requires its evidence timestamp
  -- (set in the same statement by every legitimate app path).
  IF NEW.status = 'in_transit' AND NEW.goods_received_by_traveler_at IS NULL THEN
    RAISE EXCEPTION 'INCOHERENT_STATE: in_transit requires goods_received_by_traveler_at';
  END IF;
  IF NEW.status = 'delivered' AND NEW.goods_delivered_by_traveler_at IS NULL THEN
    RAISE EXCEPTION 'INCOHERENT_STATE: delivered requires goods_delivered_by_traveler_at';
  END IF;
  IF NEW.status = 'completed' AND NEW.goods_received_by_client_at IS NULL THEN
    RAISE EXCEPTION 'INCOHERENT_STATE: completed requires goods_received_by_client_at';
  END IF;

  RETURN NEW;
END;
$$;


--
-- TOC entry 1225 (class 1255 OID 52456)
-- Name: export_audit_trail(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.export_audit_trail(entity_uuid uuid DEFAULT NULL::uuid) RETURNS TABLE(log_id uuid, admin_name text, action text, entity text, logged_at timestamp with time zone, data_diff jsonb)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  -- Audit trail is admin-only.
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;

  RETURN QUERY
  SELECT
      a.id,
      p.full_name as admin_name,
      a.action_type,
      a.entity_name,
      a.created_at,
      jsonb_build_object('before', a.data_before, 'after', a.data_after) -- before/after payload
  FROM public.audit_logs_v2 a
  LEFT JOIN public.profiles p ON a.admin_id = p.id
  WHERE (entity_uuid IS NULL OR a.entity_id = entity_uuid)
  ORDER BY a.created_at DESC;
END;
$$;


--
-- TOC entry 517 (class 1255 OID 52663)
-- Name: fn_audit_log_v2(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_audit_log_v2() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_admin_id UUID := auth.uid();
    v_action TEXT;
    v_details JSONB;
BEGIN
    -- Determine action based on operation
    IF TG_OP = 'INSERT' THEN v_action := 'CREATE'; v_details := to_jsonb(NEW);
    ELSIF TG_OP = 'UPDATE' THEN v_action := 'UPDATE'; v_details := jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW));
    ELSIF TG_OP = 'DELETE' THEN v_action := 'DELETE'; v_details := to_jsonb(OLD);
    END IF;

    -- Only log if the caller is an admin (to avoid flooding with regular user activity)
    -- Or if it's a specific table like user_roles which is sensitive anyway
    IF (SELECT public.is_admin()) OR TG_TABLE_NAME = 'user_roles' THEN
        INSERT INTO public.admin_audit_log (admin_id, action, target_type, target_id, details)
        VALUES (
            v_admin_id,
            TG_TABLE_NAME || '_' || v_action,
            TG_TABLE_NAME,
            COALESCE(NEW.id, OLD.id)::TEXT,
            v_details
        );
    END IF;

    RETURN NULL; -- result is ignored for AFTER triggers
END;
$$;


--
-- TOC entry 1192 (class 1255 OID 59985)
-- Name: fn_auto_mark_trip_full(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auto_mark_trip_full() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Only act if the booking status changed to a state that indicates active delivery/completion
    IF NEW.status IN ('completed', 'delivered', 'inTransit') AND (OLD.status IS NULL OR OLD.status != NEW.status) THEN
        
        -- Check if the trip isn't already full/completed/cancelled
        IF EXISTS (
            SELECT 1 FROM public.trips 
            WHERE id = NEW.trip_id AND status NOT IN ('full', 'completed', 'cancelled')
        ) THEN
            -- Update the trip to 'full'
            UPDATE public.trips
            SET status = 'full'
            WHERE id = NEW.trip_id;

            -- Auto-reject any pending or inCommunication bookings for this trip
            UPDATE public.bookings
            SET status = 'rejected'
            WHERE trip_id = NEW.trip_id 
              AND status IN ('pending', 'inCommunication')
              AND id != NEW.id;
        END IF;

    END IF;

    RETURN NEW;
END;
$$;


--
-- TOC entry 1200 (class 1255 OID 52669)
-- Name: fn_enforce_booking_integrity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_enforce_booking_integrity() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Prevent closing disputed bookings without internal_notes
    IF NEW.status = 'completed' AND OLD.status = 'disputed' AND NEW.internal_notes IS NULL THEN
        RAISE EXCEPTION 'Integrity Error: Disputed bookings require admin notes before completion.';
    END IF;
    RETURN NEW;
END;
$$;


--
-- TOC entry 607 (class 1255 OID 59987)
-- Name: fn_expire_past_trips(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_expire_past_trips() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    trip_record RECORD;
BEGIN
    -- Find active trips where departure_time is in the past
    FOR trip_record IN 
        SELECT id FROM public.trips
        WHERE status IN ('available', 'pendingConfirmation', 'booked', 'inCommunication')
          AND departure_time < NOW()
    LOOP
        -- Mark trip as full
        UPDATE public.trips
        SET status = 'full'
        WHERE id = trip_record.id;

        -- Auto-reject any pending or inCommunication bookings
        UPDATE public.bookings
        SET status = 'rejected'
        WHERE trip_id = trip_record.id 
          AND status IN ('pending', 'inCommunication');
          
    END LOOP;
END;
$$;


--
-- TOC entry 1269 (class 1255 OID 94329)
-- Name: fn_generate_booking_delivery_code(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_generate_booking_delivery_code() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.delivery_codes (booking_id, code)
  VALUES (NEW.id, public.fn_new_delivery_code())
  ON CONFLICT (booking_id) DO NOTHING;
  RETURN NEW;
END;
$$;


--
-- TOC entry 758 (class 1255 OID 94341)
-- Name: fn_guard_bookings_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_guard_bookings_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF auth.uid() IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;
  NEW.delivery_code := NULL;  -- server generates the real code
  IF NEW.status NOT IN ('pending', 'in_communication') THEN
    RAISE EXCEPTION 'FORBIDDEN: new bookings must start as pending or in_communication';
  END IF;
  NEW.goods_handed_by_sender_at := NULL;
  NEW.goods_received_by_traveler_at := NULL;
  NEW.payment_marked_by_sender_at := NULL;
  NEW.payment_confirmed_by_traveler_at := NULL;
  NEW.goods_delivered_by_traveler_at := NULL;
  NEW.goods_received_by_client_at := NULL;
  NEW.delivery_code_verified_at := NULL;
  RETURN NEW;
END;
$$;


--
-- TOC entry 719 (class 1255 OID 94339)
-- Name: fn_guard_bookings_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_guard_bookings_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_otp_ok boolean := COALESCE(current_setting('tripship.delivery_verified', true), '') = 'true';
BEGIN
  IF v_uid IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  NEW.delivery_code := OLD.delivery_code;
  NEW.requester_id := OLD.requester_id;
  NEW.traveler_id := OLD.traveler_id;
  NEW.trip_id := OLD.trip_id;

  -- Admin-only columns (dispute handling, moderation).
  IF NEW.internal_notes      IS DISTINCT FROM OLD.internal_notes
  OR NEW.refund_status       IS DISTINCT FROM OLD.refund_status
  OR NEW.dispute_outcome     IS DISTINCT FROM OLD.dispute_outcome
  OR NEW.dispute_resolved_at IS DISTINCT FROM OLD.dispute_resolved_at
  OR NEW.dispute_resolved_by IS DISTINCT FROM OLD.dispute_resolved_by
  THEN
    RAISE EXCEPTION 'FORBIDDEN: admin-only booking fields';
  END IF;

  -- Write-once handshake timestamps (dispute evidence).
  IF (OLD.goods_handed_by_sender_at      IS NOT NULL AND NEW.goods_handed_by_sender_at      IS DISTINCT FROM OLD.goods_handed_by_sender_at)
  OR (OLD.goods_received_by_traveler_at  IS NOT NULL AND NEW.goods_received_by_traveler_at  IS DISTINCT FROM OLD.goods_received_by_traveler_at)
  OR (OLD.payment_marked_by_sender_at    IS NOT NULL AND NEW.payment_marked_by_sender_at    IS DISTINCT FROM OLD.payment_marked_by_sender_at)
  OR (OLD.payment_confirmed_by_traveler_at IS NOT NULL AND NEW.payment_confirmed_by_traveler_at IS DISTINCT FROM OLD.payment_confirmed_by_traveler_at)
  OR (OLD.goods_delivered_by_traveler_at IS NOT NULL AND NEW.goods_delivered_by_traveler_at IS DISTINCT FROM OLD.goods_delivered_by_traveler_at)
  OR (OLD.goods_received_by_client_at    IS NOT NULL AND NEW.goods_received_by_client_at    IS DISTINCT FROM OLD.goods_received_by_client_at)
  OR (OLD.delivery_code_verified_at      IS NOT NULL AND NEW.delivery_code_verified_at      IS DISTINCT FROM OLD.delivery_code_verified_at)
  THEN
    RAISE EXCEPTION 'TIMESTAMP_IMMUTABLE: handshake timestamps are write-once';
  END IF;

  -- The agreed price freezes once goods are moving.
  IF NEW.price IS DISTINCT FROM OLD.price
     AND OLD.status IN ('in_transit', 'delivered', 'completed', 'cancelled', 'rejected') THEN
    RAISE EXCEPTION 'FORBIDDEN: price is frozen after transit starts';
  END IF;

  -- Role rules for status moves (the FSM trigger handles sequence legality).
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NEW.status IN ('accepted', 'rejected', 'in_transit', 'delivered')
       AND v_uid <> OLD.traveler_id THEN
      RAISE EXCEPTION 'FORBIDDEN: only the driver can set %', NEW.status;
    END IF;
    IF NEW.status = 'pending' AND v_uid <> OLD.requester_id THEN
      RAISE EXCEPTION 'FORBIDDEN: only the requester can set pending';
    END IF;
    IF NEW.status = 'completed' AND v_uid <> OLD.requester_id AND NOT v_otp_ok THEN
      RAISE EXCEPTION 'FORBIDDEN: completion requires the delivery code or sender confirmation';
    END IF;
  END IF;

  -- The driver cannot fabricate client receipt / OTP verification.
  IF v_uid = OLD.traveler_id AND NOT v_otp_ok THEN
    IF (OLD.goods_received_by_client_at IS NULL AND NEW.goods_received_by_client_at IS NOT NULL)
    OR (OLD.delivery_code_verified_at   IS NULL AND NEW.delivery_code_verified_at   IS NOT NULL)
    THEN
      RAISE EXCEPTION 'FORBIDDEN: client receipt can only be confirmed by the sender or via delivery code';
    END IF;
  END IF;

  -- The requester cannot fabricate driver-side actions.
  IF v_uid = OLD.requester_id THEN
    IF (OLD.goods_received_by_traveler_at  IS NULL AND NEW.goods_received_by_traveler_at  IS NOT NULL)
    OR (OLD.payment_confirmed_by_traveler_at IS NULL AND NEW.payment_confirmed_by_traveler_at IS NOT NULL)
    OR (OLD.goods_delivered_by_traveler_at IS NULL AND NEW.goods_delivered_by_traveler_at IS NOT NULL)
    THEN
      RAISE EXCEPTION 'FORBIDDEN: driver-side timestamps can only be set by the driver';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


--
-- TOC entry 950 (class 1255 OID 94343)
-- Name: fn_guard_trips_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_guard_trips_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF auth.uid() IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;
  IF OLD.status IN ('completed', 'cancelled')
     AND (to_jsonb(NEW) - 'updated_at') <> (to_jsonb(OLD) - 'updated_at') THEN
    RAISE EXCEPTION 'TRIP_LOCKED: % trips cannot be modified', OLD.status;
  END IF;
  RETURN NEW;
END;
$$;


--
-- TOC entry 883 (class 1255 OID 52675)
-- Name: fn_handle_expiry_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_handle_expiry_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    IF NEW.identity_expiry > NOW() AND OLD.identity_expiry <= NOW() AND NEW.is_suspended = true THEN
        -- Only clear if the suspension reason was specifically for expiry
        IF NEW.internal_notes LIKE '%[Auto-Suspension] Identity Expired.%' THEN
            NEW.is_suspended := false;
            NEW.internal_notes := NEW.internal_notes || ' [System] Suspension lifted due to document renewal at ' || NOW();
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


--
-- TOC entry 712 (class 1255 OID 94347)
-- Name: fn_new_delivery_code(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_new_delivery_code() RETURNS text
    LANGUAGE sql
    AS $$
  -- 1000..9999 from two CSPRNG bytes (modulo bias is irrelevant at this
  -- range, and codes are attempt-limited server-side anyway).
  -- pgcrypto lives in the `extensions` schema; callers run with
  -- search_path = public, so the call must be schema-qualified.
  SELECT (1000 + (('x' || encode(extensions.gen_random_bytes(2), 'hex'))::bit(16)::int % 9000))::text;
$$;


--
-- TOC entry 974 (class 1255 OID 52543)
-- Name: fn_report_risk_sync(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_report_risk_sync() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF (NEW.status = 'resolved' AND OLD.status <> 'resolved')
     OR (NEW.status <> 'resolved' AND OLD.status = 'resolved') THEN
    -- Fire profile risk-sync trigger by touching a tracked column as a no-op.
    UPDATE public.profiles
    SET strike_count = strike_count
    WHERE id = NEW.reported_id;
  END IF;

  RETURN NEW;
END;
$$;


--
-- TOC entry 1145 (class 1255 OID 93285)
-- Name: fn_set_ads_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_set_ads_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- TOC entry 605 (class 1255 OID 55191)
-- Name: fn_set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- TOC entry 463 (class 1255 OID 52677)
-- Name: fn_sync_approvals_count(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_sync_approvals_count() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    NEW.approvals_count := array_length(NEW.approver_ids, 1);
    IF NEW.approvals_count IS NULL THEN NEW.approvals_count := 0; END IF;
    RETURN NEW;
END;
$$;


--
-- TOC entry 1268 (class 1255 OID 52541)
-- Name: fn_sync_user_risk_score(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_sync_user_risk_score() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_score INT := 100;
    v_strikes INT;
    v_reports_upheld INT;
    v_old_score INT;
    v_tier TEXT := 'none';
BEGIN
    -- Get current strikes
    SELECT strike_count INTO v_strikes FROM public.profiles WHERE id = NEW.id;
    v_score := v_score - (v_strikes * (SELECT weight FROM public.risk_config WHERE key = 'strike_penalty'));

    -- Get upheld reports
    SELECT count(*) INTO v_reports_upheld FROM public.reports 
    WHERE reported_id = NEW.id AND status = 'resolved';
    v_score := v_score - (v_reports_upheld * (SELECT weight FROM public.risk_config WHERE key = 'report_upheld'));

    -- Clamp score
    IF v_score < 0 THEN v_score := 0; END IF;

    -- Determine Tier
    IF v_score < 20 THEN v_tier := 'full_suspension';
    ELSIF v_score < 50 THEN v_tier := 'booking_lock';
    ELSIF v_score < 75 THEN v_tier := 'chat_only';
    END IF;

    -- Get old score to check for delta
    SELECT risk_score INTO v_old_score FROM public.user_risk_scores WHERE user_id = NEW.id;

    -- Update Risk Score
    INSERT INTO public.user_risk_scores (user_id, risk_score, restriction_tier, last_recalculated_at)
    VALUES (NEW.id, v_score, v_tier, NOW())
    ON CONFLICT (user_id) DO UPDATE SET 
        risk_score = EXCLUDED.risk_score,
        restriction_tier = EXCLUDED.restriction_tier,
        last_recalculated_at = EXCLUDED.last_recalculated_at;

    -- Record History if delta exists
    IF v_old_score IS DISTINCT FROM v_score THEN
        INSERT INTO public.risk_score_history (user_id, old_score, new_score, reason)
        VALUES (NEW.id, v_old_score, v_score, 'Automated recalculation on behavioral change');
    END IF;

    -- Auto-Restriction Enforcement
    IF v_tier = 'full_suspension' AND (OLD.is_suspended IS FALSE OR OLD.is_suspended IS NULL) THEN
        -- We won't auto-suspend profiles directly here to avoid recursive trigger issues
        -- Instead, we flag it for admin review or use a scheduled worker
        -- But for this task, we can update is_suspended IF we are careful
    END IF;

    RETURN NEW;
END;
$$;


--
-- TOC entry 989 (class 1255 OID 39678)
-- Name: get_dashboard_stats(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_dashboard_stats() RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  total_users integer;
  total_drivers integer;
  active_trips integer;
  monthly_growth json;
BEGIN
  -- 1. Total Users
  SELECT count(*) INTO total_users FROM profiles;

  -- 2. Total Drivers
  SELECT count(*) INTO total_drivers FROM profiles WHERE traveler_status != 'none';

  -- 3. Active Trips (available, in_transit, booked, etc.)
  SELECT count(*) INTO active_trips
  FROM trips
  WHERE status IN ('available', 'booked', 'in_transit', 'pending_confirmation');

  -- 4. Monthly Growth (Last 12 months)
  WITH months AS (
    SELECT generate_series(
      date_trunc('month', current_date) - interval '11 months',
      date_trunc('month', current_date),
      '1 month'::interval
    ) AS month
  ),
  user_counts AS (
    SELECT date_trunc('month', created_at) AS month, count(*) AS count
    FROM profiles
    GROUP BY 1
  ),
  driver_counts AS (
    SELECT date_trunc('month', created_at) AS month, count(*) AS count
    FROM profiles
    WHERE traveler_status != 'none'
    GROUP BY 1
  ),
  trip_counts AS (
    SELECT date_trunc('month', created_at) AS month, count(*) AS count
    FROM trips
    GROUP BY 1
  )
  SELECT json_agg(
    json_build_object(
      'month', to_char(m.month, 'Mon'),
      'year', to_char(m.month, 'YYYY'),
      'users', coalesce(uc.count, 0),
      'drivers', coalesce(dc.count, 0),
      'trips', coalesce(tc.count, 0)
    ) ORDER BY m.month DESC
  ) INTO monthly_growth
  FROM months m
  LEFT JOIN user_counts uc ON m.month = uc.month
  LEFT JOIN driver_counts dc ON m.month = dc.month
  LEFT JOIN trip_counts tc ON m.month = tc.month;

  RETURN json_build_object(
    'total_users', total_users,
    'total_drivers', total_drivers,
    'active_trips', active_trips,
    'monthly_growth', monthly_growth
  );
END;
$$;


--
-- Name: is_home_country(text, text); Type: FUNCTION; Schema: public; Owner: -
-- White-label seam: the home country for the internal/external route split.
-- A fork sets its country by editing the two literals below (mirror of the
-- app's GeographyConfig). Every route RPC/trigger calls this instead of
-- hardcoding the country.
--

CREATE FUNCTION public.is_home_country(country_code text, name_en text, name_ar text) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
  SELECT CASE WHEN country_code IS NOT NULL AND length(trim(country_code)) > 0 THEN upper(trim(country_code)) IN ('AE', 'ARE') ELSE lower(coalesce(name_en, '')) IN ('united arab emirates', 'uae')
      OR coalesce(name_ar, '') IN ('الإمارات العربية المتحدة', 'الإمارات') END;
$$;


--
-- TOC entry 409 (class 1259 OID 23066)
-- Name: trips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trips (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    traveler_id uuid NOT NULL,
    origin_location_id uuid NOT NULL,
    dest_location_id uuid NOT NULL,
    trip_type text DEFAULT 'scheduled'::text NOT NULL,
    departure_time timestamp with time zone NOT NULL,
    status text DEFAULT 'available'::text,
    max_weight_kg double precision,
    suggested_price_per_kg numeric,
    suggested_flat_price numeric,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    notes text,
    current_load_kg numeric DEFAULT 0,
    internal_notes text,
    cancellation_reason text,
    CONSTRAINT trips_status_check CHECK ((status = ANY (ARRAY['available'::text, 'in_communication'::text, 'pending_confirmation'::text, 'booked'::text, 'in_transit'::text, 'full'::text, 'cancelled'::text, 'completed'::text]))),
    CONSTRAINT trips_trip_type_check CHECK ((trip_type = ANY (ARRAY['scheduled'::text, 'on_demand'::text])))
);


--
-- TOC entry 5661 (class 0 OID 0)
-- Dependencies: 409
-- Name: COLUMN trips.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.trips.status IS 'Trip lifecycle status: available, in_communication, pending_confirmation, booked, in_transit, full, cancelled, completed';


--
-- TOC entry 1026 (class 1255 OID 28997)
-- Name: get_filtered_trips(boolean, uuid, uuid, uuid, text, double precision, text, text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_filtered_trips(p_is_internal boolean DEFAULT true, p_traveler_id uuid DEFAULT NULL::uuid, p_origin_loc_id uuid DEFAULT NULL::uuid, p_dest_loc_id uuid DEFAULT NULL::uuid, p_vehicle_type text DEFAULT NULL::text, p_min_weight double precision DEFAULT NULL::double precision, p_date text DEFAULT NULL::text, p_origin_city_name text DEFAULT NULL::text, p_dest_city_name text DEFAULT NULL::text, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0) RETURNS SETOF public.trips
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT t.*
  FROM public.trips t
  LEFT JOIN public.locations o ON t.origin_location_id = o.id
  LEFT JOIN public.locations d ON t.dest_location_id = d.id
  WHERE (p_traveler_id IS NULL OR t.traveler_id = p_traveler_id)
    AND (p_origin_loc_id IS NULL OR t.origin_location_id = p_origin_loc_id)
    AND (p_dest_loc_id IS NULL OR t.dest_location_id = p_dest_loc_id)
    AND (p_min_weight IS NULL OR (t.max_weight_kg IS NOT NULL AND t.max_weight_kg >= p_min_weight))
    AND (p_date IS NULL OR (t.departure_time::date = (p_date::date)))
    AND (
      p_origin_city_name IS NULL
      OR o.city_name_ar ILIKE '%' || p_origin_city_name || '%'
      OR o.city_name_en ILIKE '%' || p_origin_city_name || '%'
    )
    AND (
      p_dest_city_name IS NULL
      OR d.city_name_ar ILIKE '%' || p_dest_city_name || '%'
      OR d.city_name_en ILIKE '%' || p_dest_city_name || '%'
    )
  ORDER BY t.departure_time ASC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


--
-- TOC entry 419 (class 1259 OID 31328)
-- Name: route_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.route_alerts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    origin_location_id uuid,
    dest_location_id uuid,
    origin_province text,
    dest_province text,
    origin_city text,
    dest_city text,
    is_internal boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- TOC entry 845 (class 1255 OID 35881)
-- Name: get_my_route_alerts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_my_route_alerts() RETURNS SETOF public.route_alerts
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT * FROM public.route_alerts
  WHERE user_id = auth.uid()
  ORDER BY created_at DESC;
$$;


--
-- TOC entry 743 (class 1255 OID 52319)
-- Name: get_public_index_names(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_public_index_names() RETURNS SETOF text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT indexname::text
  FROM pg_indexes
  WHERE schemaname = 'public'
  ORDER BY indexname;
$$;


--
-- TOC entry 5662 (class 0 OID 0)
-- Dependencies: 743
-- Name: FUNCTION get_public_index_names(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.get_public_index_names() IS 'Used by perf regression tests to assert Stage 3 indexes exist.';


--
-- TOC entry 1356 (class 1255 OID 52660)
-- Name: get_table_stats(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_table_stats(table_name_param text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    row_count BIGINT;
BEGIN
    EXECUTE format('SELECT count(*) FROM %I', table_name_param) INTO row_count;
    RETURN jsonb_build_object('total_count', row_count);
END;
$$;


--
-- TOC entry 484 (class 1255 OID 52498)
-- Name: get_user_dispute_rate(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_dispute_rate(p_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
    v_total_bookings INT;
    v_disputed_bookings INT;
    v_rate NUMERIC;
BEGIN
    SELECT COUNT(*) INTO v_total_bookings 
    FROM public.bookings 
    WHERE requester_id = p_user_id OR traveler_id = p_user_id;

    SELECT COUNT(*) INTO v_disputed_bookings
    FROM public.bookings
    WHERE (requester_id = p_user_id OR traveler_id = p_user_id)
    AND (status = 'disputed' OR payment_disputed_at IS NOT NULL);

    IF v_total_bookings = 0 THEN
        v_rate := 0;
    ELSE
        v_rate := (v_disputed_bookings::NUMERIC / v_total_bookings::NUMERIC) * 100;
    END IF;

    RETURN jsonb_build_object(
        'total', v_total_bookings,
        'disputed', v_disputed_bookings,
        'rate', ROUND(v_rate, 2)
    );
END;
$$;


--
-- TOC entry 1164 (class 1255 OID 39584)
-- Name: get_user_ratings(uuid, public.rating_role); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_ratings(p_user_id uuid, p_role public.rating_role) RETURNS TABLE(id uuid, rater_id uuid, rated_id uuid, role_rated public.rating_role, rating integer, comment text, comment_status text, booking_id uuid, created_at timestamp with time zone, rater_full_name text, rater_avatar_url text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT
    r.id,
    r.rater_id,
    r.rated_id,
    r.role_rated,
    r.rating,
    CASE
      WHEN r.comment_status = 'approved' THEN r.comment
      WHEN r.rater_id = auth.uid() THEN r.comment
      ELSE NULL
    END AS comment,
    CASE
      WHEN r.rater_id = auth.uid() THEN r.comment_status
      ELSE NULL
    END AS comment_status,
    r.booking_id,
    r.created_at,
    p.full_name AS rater_full_name,
    p.avatar_url AS rater_avatar_url
  FROM public.ratings r
  LEFT JOIN public.profiles p ON p.id = r.rater_id
  WHERE r.rated_id = p_user_id
    AND r.role_rated = p_role
  ORDER BY r.created_at DESC;
$$;


--
-- TOC entry 585 (class 1255 OID 29060)
-- Name: handle_new_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_notification() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_key text;
BEGIN
  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  PERFORM net.http_post(
    url := 'https://jkeimaazqmsataoeigsf.supabase.co/functions/v1/push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || COALESCE(v_key, '')
    ),
    body := jsonb_build_object('record', row_to_json(NEW)),
    timeout_milliseconds := 5000
  );
  RETURN NEW;
END;
$$;


--
-- TOC entry 771 (class 1255 OID 19054)
-- Name: handle_new_rating(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_rating() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if NEW.role_rated = 'driver' then
    update public.profiles
    set traveler_rating_avg = (select avg(rating)::numeric from public.ratings where rated_id = NEW.rated_id and role_rated = 'driver'),
        traveler_rating_count = (select count(*) from public.ratings where rated_id = NEW.rated_id and role_rated = 'driver')
    where id = NEW.rated_id;
  elsif NEW.role_rated = 'client' then
    update public.profiles
    set client_rating_avg = (select avg(rating)::numeric from public.ratings where rated_id = NEW.rated_id and role_rated = 'client'),
        client_rating_count = (select count(*) from public.ratings where rated_id = NEW.rated_id and role_rated = 'client')
    where id = NEW.rated_id;
  end if;
  return NEW;
end;
$$;


--
-- TOC entry 556 (class 1255 OID 18931)
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
    now()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;


--
-- TOC entry 1098 (class 1255 OID 61181)
-- Name: has_active_engagement(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_active_engagement(p_user_a uuid, p_user_b uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_has_active BOOLEAN := FALSE;
BEGIN
  -- Check for active bookings in Trips
  -- Only block if the goods have been handed over to the driver and are en route
  -- 'in_transit': Goods are being transported
  SELECT EXISTS (
    SELECT 1 FROM bookings
    WHERE 
      ((traveler_id = p_user_a AND requester_id = p_user_b) OR 
       (traveler_id = p_user_b AND requester_id = p_user_a))
      AND status = 'in_transit'
  ) INTO v_has_active;

  IF v_has_active THEN
    RETURN TRUE;
  END IF;

  RETURN v_has_active;
END;
$$;


--
-- TOC entry 666 (class 1255 OID 52425)
-- Name: has_role(public.admin_role); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_role(required_role public.admin_role) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT public.is_admin();
$$;


--
-- TOC entry 1365 (class 1255 OID 26584)
-- Name: has_user_interacted_with_trip(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_user_interacted_with_trip(p_user_id uuid, p_trip_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.bookings
    WHERE requester_id = p_user_id
      AND trip_id = p_trip_id
  );
END;
$$;


--
-- TOC entry 510 (class 1255 OID 21563)
-- Name: is_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_admin() RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.is_admin = true
  );
$$;


--
-- TOC entry 582 (class 1255 OID 45267)
-- Name: is_driver_allowed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_driver_allowed() RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.traveler_status = 'approved'
      AND p.is_suspended = false
      AND p.is_driver = true
      -- Optional extra safety: ensure there is at least one vehicle row
      AND EXISTS (
        SELECT 1 FROM public.vehicles v WHERE v.owner_id = p.id
      )
  );
$$;


--
-- TOC entry 608 (class 1255 OID 39372)
-- Name: is_moderator_or_above(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_moderator_or_above() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT public.is_admin();
$$;


--
-- TOC entry 1247 (class 1255 OID 39644)
-- Name: is_user_blocked(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_user_blocked() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND (
        is_suspended = true
        OR traveler_status = 'blocked'
      )
  );
$$;


--
-- TOC entry 1053 (class 1255 OID 31354)
-- Name: notify_matching_alerts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_matching_alerts() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    origin_loc RECORD;
    dest_loc RECORD;
    alert_record RECORD;
BEGIN
    SELECT * INTO origin_loc FROM public.locations WHERE id = NEW.origin_location_id;
    SELECT * INTO dest_loc FROM public.locations WHERE id = NEW.dest_location_id;
    FOR alert_record IN
        SELECT * FROM public.route_alerts
        WHERE is_internal = (
            CASE
                WHEN public.is_home_country(origin_loc.country_code, origin_loc.country_name_en, origin_loc.country_name_ar) AND public.is_home_country(dest_loc.country_code, dest_loc.country_name_en, dest_loc.country_name_ar) THEN true
                ELSE false
            END
        )
        AND (
            (origin_location_id IS NOT NULL AND origin_location_id = NEW.origin_location_id)
            OR
            (
                (origin_city IS NOT NULL AND (origin_loc.city_name_ar = origin_city OR origin_loc.city_name_en = origin_city))
                OR
                (origin_province IS NOT NULL AND (origin_loc.province_name_ar = origin_province OR origin_loc.province_name_en = origin_province))
            )
        )
        AND (
            (dest_location_id IS NOT NULL AND dest_location_id = NEW.dest_location_id)
            OR
            (
                (dest_city IS NOT NULL AND (dest_loc.city_name_ar = dest_city OR dest_loc.city_name_en = dest_city))
                OR
                (dest_province IS NOT NULL AND (dest_loc.province_name_ar = dest_province OR dest_loc.province_name_en = dest_province))
            )
        )
    LOOP
        INSERT INTO public.notifications (user_id, title, body, data)
        VALUES (
            alert_record.user_id,
            'رحلة جديدة متاحة! (New Trip Available)',
            'رحلة جديدة متوفرة الآن تطابق تنبيهك من ' || COALESCE(origin_loc.city_name_ar, origin_loc.province_name_ar) || ' إلى ' || COALESCE(dest_loc.city_name_ar, dest_loc.province_name_ar),
            jsonb_build_object(
                'type', 'new_matching_trip',
                'trip_id', NEW.id,
                'origin', origin_loc.city_name_ar,
                'destination', dest_loc.city_name_ar,
                'recipient_role', 'sender'
            )
        );
    END LOOP;
    RETURN NEW;
END;
$$;


--
-- TOC entry 528 (class 1255 OID 52448)
-- Name: proc_universal_audit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.proc_universal_audit() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  old_data JSONB := null;
  new_data JSONB := null;
  admin_uid UUID := auth.uid();
  client_ip INET;
  client_ua TEXT;
  audit_entity_id UUID;
BEGIN
    -- Only log if it's an admin acting (or if no auth.uid() it might be system/migration)
    -- We generally want to log all mutations to these tables.
    
    -- Attempt to get IP and UserAgent from PostgREST headers
    BEGIN
        client_ip := current_setting('request.header.x-real-ip', true)::INET;
    EXCEPTION WHEN OTHERS THEN
        client_ip := null;
    END;

    BEGIN
        client_ua := current_setting('request.header.user-agent', true);
    EXCEPTION WHEN OTHERS THEN
        client_ua := null;
    END;

    -- Determine entity ID (assuming most tables have 'id')
    IF (TG_OP = 'DELETE') THEN
        old_data := to_jsonb(OLD);
        audit_entity_id := OLD.id;
    ELSIF (TG_OP = 'UPDATE') THEN
        old_data := to_jsonb(OLD);
        new_data := to_jsonb(NEW);
        audit_entity_id := NEW.id;
    ELSIF (TG_OP = 'INSERT') THEN
        new_data := to_jsonb(NEW);
        audit_entity_id := NEW.id;
    END IF;

    -- Insert into audit log
    INSERT INTO public.audit_logs_v2 (
        admin_id,
        action_type,
        entity_name,
        entity_id,
        data_before,
        data_after,
        ip_address,
        user_agent
    ) VALUES (
        admin_uid,
        TG_OP,
        TG_TABLE_NAME,
        audit_entity_id,
        old_data,
        new_data,
        client_ip,
        client_ua
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- TOC entry 1074 (class 1255 OID 39323)
-- Name: protect_admin_columns(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.protect_admin_columns() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  -- Only admins (or service_role via Edge Functions) can change these columns
  IF NOT public.is_admin() THEN
    NEW.is_admin := OLD.is_admin;
    NEW.is_suspended := OLD.is_suspended;
    
    -- Allow users to submit applications and upgrades:
    -- 1. Initial application: 'none' -> 'pending'
    -- 2. Upgrade to driver: 'approved' -> 'pending' (when adding vehicle)
    -- But prevent self-approval or other unauthorized changes
    IF NOT (
      (OLD.traveler_status = 'none' AND NEW.traveler_status = 'pending') OR
      (OLD.traveler_status = 'approved' AND NEW.traveler_status = 'pending') OR
      (OLD.traveler_status = NEW.traveler_status)
    ) THEN
      NEW.traveler_status := OLD.traveler_status;
    END IF;
    
    NEW.traveler_rating_avg := OLD.traveler_rating_avg;
    NEW.traveler_rating_count := OLD.traveler_rating_count;
    NEW.client_rating_avg := OLD.client_rating_avg;
    NEW.client_rating_count := OLD.client_rating_count;
    NEW.subscription_expires_at := OLD.subscription_expires_at;
    NEW.license_expires_at := OLD.license_expires_at;
    NEW.driver_validity_date := OLD.driver_validity_date;
  END IF;
  RETURN NEW;
END;
$$;


--
-- TOC entry 5663 (class 0 OID 0)
-- Dependencies: 1074
-- Name: FUNCTION protect_admin_columns(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.protect_admin_columns() IS 'Protects admin-only columns while allowing users to submit applications (none->pending) and upgrades (approved->pending)';


--
-- TOC entry 1337 (class 1255 OID 52339)
-- Name: protect_profile_metadata(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.protect_profile_metadata() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF NOT public.is_admin() THEN
    IF (NEW.is_admin IS DISTINCT FROM OLD.is_admin)
      OR (NEW.is_suspended IS DISTINCT FROM OLD.is_suspended)
      OR (NEW.deleted_at IS DISTINCT FROM OLD.deleted_at)
      OR (NEW.is_frozen IS DISTINCT FROM OLD.is_frozen)
      OR (NEW.strike_count IS DISTINCT FROM OLD.strike_count)
      OR (NEW.internal_notes IS DISTINCT FROM OLD.internal_notes)
      OR (NEW.is_blocked IS DISTINCT FROM OLD.is_blocked)
      OR (NEW.blocked_reason IS DISTINCT FROM OLD.blocked_reason)
      OR (NEW.blocked_at IS DISTINCT FROM OLD.blocked_at)
      OR (NEW.blocked_by IS DISTINCT FROM OLD.blocked_by)
      OR (NEW.is_trusted IS DISTINCT FROM OLD.is_trusted)
      OR (NEW.is_featured IS DISTINCT FROM OLD.is_featured)
      OR (NEW.trust_badge IS DISTINCT FROM OLD.trust_badge)
      OR (NEW.trust_badge_set_at IS DISTINCT FROM OLD.trust_badge_set_at)
      OR (NEW.trust_badge_set_by IS DISTINCT FROM OLD.trust_badge_set_by) THEN
      RAISE EXCEPTION 'Access denied. Account governance is restricted to admins.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


--
-- TOC entry 792 (class 1255 OID 93382)
-- Name: record_admin_login_event(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_admin_login_event() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  caller_id uuid := auth.uid();
  headers jsonb := COALESCE(NULLIF(current_setting('request.headers', true), '')::jsonb, '{}'::jsonb);
  raw_ip text;
  clean_ip text;
  country_header text;
  user_agent_header text;
  admin_email text;
BEGIN
  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  raw_ip := COALESCE(
    headers->>'cf-connecting-ip',
    headers->>'x-real-ip',
    headers->>'x-forwarded-for'
  );
  clean_ip := NULLIF(trim(split_part(COALESCE(raw_ip, ''), ',', 1)), '');

  country_header := NULLIF(upper(trim(COALESCE(
    headers->>'cf-ipcountry',
    headers->>'x-vercel-ip-country',
    headers->>'x-country-code',
    ''
  ))), '');
  IF country_header = 'XX' THEN
    country_header := NULL;
  END IF;

  user_agent_header := NULLIF(trim(COALESCE(headers->>'user-agent', '')), '');

  SELECT u.email
  INTO admin_email
  FROM auth.users u
  WHERE u.id = caller_id;

  INSERT INTO public.admin_login_events (
    admin_id,
    email,
    ip_address,
    country,
    user_agent
  )
  VALUES (
    caller_id,
    admin_email,
    clean_ip,
    country_header,
    user_agent_header
  );
END;
$$;


--
-- TOC entry 1270 (class 1255 OID 93403)
-- Name: record_admin_logout_event(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_admin_logout_event() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  caller_id uuid := auth.uid();
  headers jsonb := COALESCE(NULLIF(current_setting('request.headers', true), '')::jsonb, '{}'::jsonb);
  raw_ip text;
  clean_ip text;
  country_header text;
  user_agent_header text;
  admin_email text;
BEGIN
  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  raw_ip := COALESCE(
    headers->>'cf-connecting-ip',
    headers->>'x-real-ip',
    headers->>'x-forwarded-for'
  );
  clean_ip := NULLIF(trim(split_part(COALESCE(raw_ip, ''), ',', 1)), '');

  country_header := NULLIF(upper(trim(COALESCE(
    headers->>'cf-ipcountry',
    headers->>'x-vercel-ip-country',
    headers->>'x-country-code',
    ''
  ))), '');
  IF country_header = 'XX' THEN
    country_header := NULL;
  END IF;

  user_agent_header := NULLIF(trim(COALESCE(headers->>'user-agent', '')), '');

  SELECT u.email
  INTO admin_email
  FROM auth.users u
  WHERE u.id = caller_id;

  INSERT INTO public.admin_login_events (
    admin_id,
    email,
    ip_address,
    country,
    user_agent,
    event_type
  )
  VALUES (
    caller_id,
    admin_email,
    clean_ip,
    country_header,
    user_agent_header,
    'logout'
  );
END;
$$;


--
-- TOC entry 5664 (class 0 OID 0)
-- Dependencies: 1270
-- Name: FUNCTION record_admin_logout_event(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.record_admin_logout_event() IS 'Records admin logout events with IP address and country from HTTP headers';


--
-- TOC entry 762 (class 1255 OID 62302)
-- Name: search_trips_rpc(text, text, uuid, uuid, boolean, text, numeric, date, integer, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.search_trips_rpc(p_origin_city text DEFAULT NULL::text, p_dest_city text DEFAULT NULL::text, p_origin_location_id uuid DEFAULT NULL::uuid, p_dest_location_id uuid DEFAULT NULL::uuid, p_is_internal boolean DEFAULT NULL::boolean, p_vehicle_type text DEFAULT NULL::text, p_min_weight numeric DEFAULT NULL::numeric, p_departure_date date DEFAULT NULL::date, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0, p_traveler_id uuid DEFAULT NULL::uuid) RETURNS SETOF json
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  SELECT json_build_object(
    'id', t.id,
    'traveler_id', t.traveler_id,
    'origin_location_id', t.origin_location_id,
    'dest_location_id', t.dest_location_id,
    'departure_time', t.departure_time,
    'max_weight_kg', t.max_weight_kg,
    'suggested_price_per_kg', t.suggested_price_per_kg,
    'suggested_flat_price', t.suggested_flat_price,
    'trip_type', COALESCE(t.trip_type, 'scheduled'),
    'status', COALESCE(t.status, 'available'),
    'created_at', t.created_at,
    'notes', t.notes,
    'origin_loc', (SELECT to_jsonb(l) FROM locations l WHERE l.id = t.origin_location_id),
    'dest_loc', (SELECT to_jsonb(l) FROM locations l WHERE l.id = t.dest_location_id),
    'driver', (
      SELECT (
        to_jsonb(p) || jsonb_build_object(
          'vehicles',
          (SELECT COALESCE(json_agg(to_jsonb(v)), '[]'::json) FROM vehicles v WHERE v.owner_id = p.id)
        )
      )::json
      FROM profiles p
      WHERE p.id = t.traveler_id
    ),
    'trip_stopovers', '[]'::jsonb
  )::json
  FROM trips t
  JOIN locations origin_loc ON origin_loc.id = t.origin_location_id
  JOIN locations dest_loc ON dest_loc.id = t.dest_location_id
  JOIN profiles p ON p.id = t.traveler_id
  WHERE t.status = 'available'
    AND p.is_suspended = false
    AND p.deleted_at IS NULL
    AND (p.subscription_expires_at IS NULL OR p.subscription_expires_at > now())
    AND (p.license_expires_at IS NULL OR p.license_expires_at > now())
    AND (
      p_is_internal IS NULL OR (
        (p_is_internal = true AND public.is_home_country(origin_loc.country_code, origin_loc.country_name_en, origin_loc.country_name_ar) AND public.is_home_country(dest_loc.country_code, dest_loc.country_name_en, dest_loc.country_name_ar))
        OR
        (p_is_internal = false AND NOT (public.is_home_country(origin_loc.country_code, origin_loc.country_name_en, origin_loc.country_name_ar) AND public.is_home_country(dest_loc.country_code, dest_loc.country_name_en, dest_loc.country_name_ar)))
      )
    )
    AND (p_origin_city IS NULL OR p_origin_city = '' OR LOWER(origin_loc.city_name_en) = LOWER(p_origin_city) OR origin_loc.city_name_ar = p_origin_city)
    AND (p_dest_city IS NULL OR p_dest_city = '' OR LOWER(dest_loc.city_name_en) = LOWER(p_dest_city) OR dest_loc.city_name_ar = p_dest_city)
    AND (p_origin_location_id IS NULL OR t.origin_location_id = p_origin_location_id)
    AND (p_dest_location_id IS NULL OR t.dest_location_id = p_dest_location_id)
    AND (
      p_vehicle_type IS NULL OR p_vehicle_type = '' OR EXISTS (
        SELECT 1 FROM vehicles v WHERE v.owner_id = t.traveler_id AND v.vehicle_type = p_vehicle_type
      )
    )
    AND (p_min_weight IS NULL OR t.max_weight_kg IS NULL OR t.max_weight_kg >= p_min_weight)
    AND (p_departure_date IS NULL OR (t.departure_time AT TIME ZONE 'UTC')::date = p_departure_date)
    AND (
      p_traveler_id IS NULL
      OR (
        t.traveler_id != p_traveler_id
        AND t.id NOT IN (
          SELECT b.trip_id
          FROM public.bookings b
          WHERE b.requester_id = p_traveler_id
            AND b.status <> 'cancelled'
        )
      )
    )
  ORDER BY
    CASE WHEN COALESCE(p.is_featured, false) THEN 1 ELSE 0 END DESC,
    CASE WHEN p.promoted_until IS NOT NULL AND p.promoted_until > now() THEN 1 ELSE 0 END DESC,
    t.departure_time ASC NULLS LAST,
    t.created_at DESC
  LIMIT GREATEST(COALESCE(p_limit, 20), 1)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
$$;


--
-- TOC entry 958 (class 1255 OID 94355)
-- Name: send_user_notification(uuid, text, text, jsonb, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.send_user_notification(p_recipient_id uuid, p_title text, p_body text, p_data jsonb DEFAULT '{}'::jsonb, p_idempotency_key text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_caller uuid := auth.uid();
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;

  IF p_recipient_id IS NULL
     OR COALESCE(TRIM(p_title), '') = ''
     OR COALESCE(TRIM(p_body), '') = ''
     OR LENGTH(p_title) > 200
     OR LENGTH(p_body) > 1000 THEN
    RAISE EXCEPTION 'INVALID_INPUT';
  END IF;

  -- Self-notifications are a no-op (the client already skips them).
  IF v_caller = p_recipient_id THEN
    RETURN;
  END IF;

  IF NOT public.is_admin() THEN
    -- Blocked in either direction: drop silently (do not reveal blocking).
    IF EXISTS (
      SELECT 1 FROM public.blocks
      WHERE (blocker_id = v_caller AND blocked_id = p_recipient_id)
         OR (blocker_id = p_recipient_id AND blocked_id = v_caller)
    ) THEN
      RETURN;
    END IF;

    IF NOT (
      -- Booking participants (any status: lifecycle + rating notifications
      -- continue after completion).
      EXISTS (
        SELECT 1 FROM public.bookings b
        WHERE (b.requester_id = v_caller AND b.traveler_id = p_recipient_id)
           OR (b.traveler_id = v_caller AND b.requester_id = p_recipient_id)
      )
      -- Alert fan-out: fresh trip poster -> route-alert subscriber.
      OR (
        EXISTS (
          SELECT 1 FROM public.trips t
          WHERE t.traveler_id = v_caller
            AND t.created_at > now() - interval '15 minutes'
        )
        AND EXISTS (
          SELECT 1 FROM public.route_alerts a WHERE a.user_id = p_recipient_id
        )
      )
    ) THEN
      RAISE EXCEPTION 'FORBIDDEN: no active relationship with recipient';
    END IF;
  END IF;

  -- NULL keys never conflict (full unique index, NULLs distinct).
  INSERT INTO public.notifications (user_id, title, body, data, idempotency_key)
  VALUES (p_recipient_id, p_title, p_body, COALESCE(p_data, '{}'::jsonb), p_idempotency_key)
  ON CONFLICT (idempotency_key) DO NOTHING;
END;
$$;


--
-- TOC entry 987 (class 1255 OID 51128)
-- Name: set_user_admin(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_user_admin(target_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  caller_id uuid := auth.uid();
  is_caller_admin boolean;
  admin_count int;
BEGIN
  -- Check if there are any admins at all (bootstrap phase)
  SELECT count(*) INTO admin_count FROM public.user_roles WHERE role::text = 'admin';
  
  IF admin_count > 0 THEN
    -- If there are admins, the caller MUST be an admin
    SELECT EXISTS (
      SELECT 1 FROM public.user_roles WHERE user_id = caller_id AND role::text = 'admin'
    ) INTO is_caller_admin;
    
    IF NOT is_caller_admin THEN
      RAISE EXCEPTION 'Access denied. Caller is not an admin.';
    END IF;
  END IF;

  -- Proceed with setting admin
  INSERT INTO public.profiles (id, full_name, is_admin)
  VALUES (
    target_id,
    COALESCE((SELECT full_name FROM public.profiles WHERE id = target_id LIMIT 1), 'Admin'),
    true
  )
  ON CONFLICT (id) DO UPDATE SET is_admin = true;

  UPDATE public.profiles SET is_admin = true WHERE id = target_id;

  IF NOT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = target_id AND role::text = 'admin') THEN
    INSERT INTO public.user_roles (user_id, role, granted_by)
    VALUES (target_id, 'admin', caller_id);
  END IF;
END;
$$;


--
-- TOC entry 5665 (class 0 OID 0)
-- Dependencies: 987
-- Name: FUNCTION set_user_admin(target_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.set_user_admin(target_id uuid) IS 'Bypass RLS to set profiles.is_admin and grant admin role. Run from SQL Editor.';


--
-- TOC entry 709 (class 1255 OID 52499)
-- Name: sync_dispute_notes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_dispute_notes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW.dispute_outcome IS DISTINCT FROM OLD.dispute_outcome) AND NEW.dispute_outcome IS NOT NULL THEN
        NEW.internal_notes := COALESCE(NEW.internal_notes, '') || E'\n' || 
            '[DISPUTE_RESOLUTION] ' || now() || ': Set to ' || NEW.dispute_outcome || 
            ' by Admin ' || auth.uid();
        NEW.dispute_resolved_at := now();
        NEW.dispute_resolved_by := auth.uid();
    END IF;
    RETURN NEW;
END;
$$;


--
-- TOC entry 878 (class 1255 OID 45260)
-- Name: sync_is_driver(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_is_driver() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  update public.profiles p
  set is_driver = exists(select 1 from public.vehicles v where v.owner_id = p.id)
  where p.id = coalesce(new.owner_id, old.owner_id);
  return null;
end;
$$;


--
-- TOC entry 1390 (class 1255 OID 45263)
-- Name: sync_profile_is_driver(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_profile_is_driver(p_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  UPDATE public.profiles p
  SET is_driver = EXISTS (
    SELECT 1
    FROM public.vehicles v
    WHERE v.owner_id = p_user_id
  )
  WHERE p.id = p_user_id;
END;
$$;


--
-- TOC entry 1067 (class 1255 OID 52459)
-- Name: sync_trip_load(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_trip_load() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_trip_id UUID;
  v_new_load NUMERIC;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_trip_id := OLD.trip_id;
  ELSE
    v_trip_id := NEW.trip_id;
  END IF;

  IF v_trip_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT COALESCE(SUM(b.reserved_weight_kg), 0)
  INTO v_new_load
  FROM public.bookings b
  WHERE b.trip_id = v_trip_id
    AND b.status NOT IN ('cancelled', 'rejected');

  UPDATE public.trips
  SET current_load_kg = v_new_load
  WHERE id = v_trip_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- TOC entry 1382 (class 1255 OID 18992)
-- Name: sync_trip_locations(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_trip_locations() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.origin_lat is not null and new.origin_lng is not null then
    new.origin_location := st_setsrid(st_point(new.origin_lng, new.origin_lat), 4326);
  end if;
  if new.dest_lat is not null and new.dest_lng is not null then
    new.dest_location := st_setsrid(st_point(new.dest_lng, new.dest_lat), 4326);
  end if;
  return new;
end;
$$;


--
-- TOC entry 1086 (class 1255 OID 93360)
-- Name: touch_support_ticket_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_support_ticket_updated_at() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  UPDATE public.support_tickets
  SET updated_at = now()
  WHERE id = NEW.ticket_id;
  RETURN NEW;
END;
$$;


--
-- TOC entry 752 (class 1255 OID 45264)
-- Name: trg_sync_is_driver(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_sync_is_driver() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  perform public.sync_profile_is_driver(coalesce(new.owner_id, old.owner_id));
  return null;
end;
$$;


--
-- TOC entry 502 (class 1255 OID 45271)
-- Name: trg_vehicles_sync_is_driver(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_vehicles_sync_is_driver() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_owner_id uuid;
begin
  v_owner_id := coalesce(new.owner_id, old.owner_id);

  if v_owner_id is not null then
    perform public.sync_profile_is_driver(v_owner_id);
  end if;

  return null;
end;
$$;


--
-- TOC entry 663 (class 1255 OID 39451)
-- Name: update_rating_averages(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_rating_averages() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_rated_id uuid;
  v_role text;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_rated_id := OLD.rated_id;
    v_role := OLD.role_rated;
  ELSE
    v_rated_id := NEW.rated_id;
    v_role := NEW.role_rated;
  END IF;

  IF v_role IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  IF v_role = 'driver' THEN
    UPDATE public.profiles SET
      traveler_rating_avg = COALESCE((SELECT AVG(rating) FROM public.ratings WHERE rated_id = v_rated_id AND role_rated = 'driver'), 0),
      traveler_rating_count = COALESCE((SELECT COUNT(*) FROM public.ratings WHERE rated_id = v_rated_id AND role_rated = 'driver'), 0)
    WHERE id = v_rated_id;
  ELSIF v_role = 'client' THEN
    UPDATE public.profiles SET
      client_rating_avg = COALESCE((SELECT AVG(rating) FROM public.ratings WHERE rated_id = v_rated_id AND role_rated = 'client'), 0),
      client_rating_count = COALESCE((SELECT COUNT(*) FROM public.ratings WHERE rated_id = v_rated_id AND role_rated = 'client'), 0)
    WHERE id = v_rated_id;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- TOC entry 501 (class 1255 OID 39632)
-- Name: update_ticket_on_new_message(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_ticket_on_new_message() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  UPDATE public.support_tickets
  SET updated_at = now()
  WHERE id = NEW.ticket_id;
  RETURN NEW;
END;
$$;


--
-- TOC entry 1009 (class 1255 OID 39449)
-- Name: update_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- TOC entry 754 (class 1255 OID 56519)
-- Name: upsert_notification_token(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upsert_notification_token(p_token text, p_platform text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- We delete any existing row with this token (regardless of user_id)
  -- because a device token should only belong to one user at a time.
  DELETE FROM public.notification_tokens WHERE token = p_token;
  
  -- Insert the new token for the current user
  INSERT INTO public.notification_tokens (user_id, token, platform, updated_at)
  VALUES (auth.uid(), p_token, p_platform, now());
END;
$$;


--
-- TOC entry 834 (class 1255 OID 94332)
-- Name: verify_delivery_and_complete_booking(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verify_delivery_and_complete_booking(p_booking_id uuid, p_code text, p_delivery_photo_url text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_rec public.delivery_codes%ROWTYPE;
  v_now timestamptz := now();
BEGIN
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF v_booking.id IS NULL THEN
    RAISE EXCEPTION 'BOOKING_NOT_FOUND';
  END IF;

  IF auth.uid() IS DISTINCT FROM v_booking.traveler_id THEN
    RAISE EXCEPTION 'FORBIDDEN';
  END IF;

  IF v_booking.status NOT IN ('in_transit', 'delivered') THEN
    RAISE EXCEPTION 'ILLEGAL_TRANSITION: cannot complete from %', v_booking.status;
  END IF;

  SELECT * INTO v_rec
  FROM public.delivery_codes
  WHERE booking_id = p_booking_id
  FOR UPDATE;

  IF v_rec.id IS NULL THEN
    RETURN 'invalid_code';
  END IF;

  IF v_rec.failed_attempts >= 5 THEN
    RETURN 'code_locked';
  END IF;

  IF v_rec.code <> p_code THEN
    UPDATE public.delivery_codes
    SET failed_attempts = failed_attempts + 1
    WHERE id = v_rec.id;
    RETURN CASE WHEN v_rec.failed_attempts + 1 >= 5
                THEN 'code_locked' ELSE 'invalid_code' END;
  END IF;

  PERFORM set_config('tripship.delivery_verified', 'true', true);

  UPDATE public.bookings
  SET status = 'completed',
      goods_delivered_by_traveler_at = COALESCE(goods_delivered_by_traveler_at, v_now),
      goods_received_by_client_at    = COALESCE(goods_received_by_client_at, v_now),
      delivery_code_verified_at      = COALESCE(delivery_code_verified_at, v_now),
      delivery_photo_url = COALESCE(p_delivery_photo_url, delivery_photo_url),
      timeline = COALESCE(timeline, '[]'::jsonb) || jsonb_build_object(
        'event', 'goods_delivered_verified_otp',
        'timestamp', to_char(v_now AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
        'user_id', auth.uid()::text
      )
  WHERE id = p_booking_id;

  RETURN 'ok';
END;
$$;


--
-- TOC entry 422 (class 1259 OID 39373)
-- Name: admin_audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_audit_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid NOT NULL,
    action text NOT NULL,
    target_type text,
    target_id text,
    details jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 451 (class 1259 OID 93366)
-- Name: admin_login_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_login_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid NOT NULL,
    email text,
    ip_address text,
    country text,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    event_type text DEFAULT 'login'::text NOT NULL,
    CONSTRAINT admin_login_events_event_type_check CHECK ((event_type = ANY (ARRAY['login'::text, 'logout'::text])))
);


--
-- TOC entry 5666 (class 0 OID 0)
-- Dependencies: 451
-- Name: COLUMN admin_login_events.event_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.admin_login_events.event_type IS 'Type of session event: login or logout';


--
-- TOC entry 436 (class 1259 OID 52607)
-- Name: admin_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_preferences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid,
    table_name text NOT NULL,
    column_visibility jsonb DEFAULT '{}'::jsonb,
    page_size integer DEFAULT 50,
    theme_preference text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- TOC entry 404 (class 1259 OID 20188)
-- Name: bookings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    traveler_id uuid NOT NULL,
    price double precision NOT NULL,
    status text DEFAULT 'pending'::text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    trip_id uuid,
    message text,
    requester_id uuid,
    goods_handed_by_sender_at timestamp with time zone,
    goods_received_by_traveler_at timestamp with time zone,
    payment_marked_by_sender_at timestamp with time zone,
    payment_confirmed_by_traveler_at timestamp with time zone,
    goods_delivered_by_traveler_at timestamp with time zone,
    goods_received_by_client_at timestamp with time zone,
    timeline jsonb DEFAULT '[]'::jsonb,
    delivery_code text,
    delivery_code_verified_at timestamp with time zone,
    internal_notes text,
    is_escalated boolean DEFAULT false,
    refund_status text,
    payment_disputed_at timestamp with time zone,
    dispute_reason text,
    dispute_outcome public.dispute_outcome,
    dispute_resolved_at timestamp with time zone,
    dispute_resolved_by uuid,
    evidence_urls jsonb DEFAULT '[]'::jsonb,
    reserved_weight_kg numeric DEFAULT 0,
    pickup_photo_url text,
    delivery_photo_url text,
    CONSTRAINT bookings_reserved_weight_kg_check CHECK ((reserved_weight_kg >= (0)::numeric)),
    CONSTRAINT bookings_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'rejected'::text, 'cancelled'::text, 'in_communication'::text, 'in_transit'::text, 'delivered'::text, 'completed'::text, 'frozen'::text, 'disputed'::text])))
);


--
-- TOC entry 5667 (class 0 OID 0)
-- Dependencies: 404
-- Name: COLUMN bookings.requester_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bookings.requester_id IS 'ID of the user who created this booking request. This is the person requesting to book the trip.';


--
-- TOC entry 5668 (class 0 OID 0)
-- Dependencies: 404
-- Name: COLUMN bookings.goods_handed_by_sender_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bookings.goods_handed_by_sender_at IS 'When sender confirms they handed over the goods';


--
-- TOC entry 5669 (class 0 OID 0)
-- Dependencies: 404
-- Name: COLUMN bookings.goods_received_by_traveler_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bookings.goods_received_by_traveler_at IS 'When driver confirms they received the goods (start of transit)';


--
-- TOC entry 5670 (class 0 OID 0)
-- Dependencies: 404
-- Name: COLUMN bookings.payment_marked_by_sender_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bookings.payment_marked_by_sender_at IS 'When sender claims they paid';


--
-- TOC entry 5671 (class 0 OID 0)
-- Dependencies: 404
-- Name: COLUMN bookings.payment_confirmed_by_traveler_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bookings.payment_confirmed_by_traveler_at IS 'When driver confirms receipt of payment';


--
-- TOC entry 5672 (class 0 OID 0)
-- Dependencies: 404
-- Name: COLUMN bookings.goods_delivered_by_traveler_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bookings.goods_delivered_by_traveler_at IS 'When driver claims they delivered the goods';


--
-- TOC entry 5673 (class 0 OID 0)
-- Dependencies: 404
-- Name: COLUMN bookings.goods_received_by_client_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bookings.goods_received_by_client_at IS 'When client/receiver confirms receipt (Trip Completed)';


--
-- TOC entry 5674 (class 0 OID 0)
-- Dependencies: 404
-- Name: COLUMN bookings.delivery_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.bookings.delivery_code IS '4-digit OTP code designated for delivery verification. Visible only to sender/requester.';


--
-- TOC entry 447 (class 1259 OID 92740)
-- Name: admin_trip_classification; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.admin_trip_classification AS
 WITH trip_aggregate AS (
         SELECT t_1.id AS trip_id,
            count(b.id) FILTER (WHERE (b.status = ANY (ARRAY['cancelled'::text, 'rejected'::text]))) AS cancelled_bookings,
            count(b.id) FILTER (WHERE ((b.is_escalated = true) OR (b.payment_disputed_at IS NOT NULL))) AS problem_bookings,
            count(b.id) AS total_bookings
           FROM (public.trips t_1
             LEFT JOIN public.bookings b ON ((b.trip_id = t_1.id)))
          GROUP BY t_1.id
        )
 SELECT t.id,
    t.traveler_id,
    t.origin_location_id,
    t.dest_location_id,
    t.trip_type,
    t.departure_time,
    t.status,
    t.max_weight_kg,
    t.suggested_price_per_kg,
    t.suggested_flat_price,
    t.created_at,
    t.notes,
    t.current_load_kg,
    t.internal_notes,
    ta.cancelled_bookings,
    ta.problem_bookings,
    ta.total_bookings,
        CASE
            WHEN (t.status = 'pending_approval'::text) THEN 'pending_approval'::text
            WHEN (t.status = 'cancelled'::text) THEN 'cancelled'::text
            WHEN ((t.status = 'completed'::text) AND (COALESCE(ta.problem_bookings, (0)::bigint) = 0)) THEN 'fully_completed_clean'::text
            WHEN ((t.status = 'completed'::text) AND (COALESCE(ta.problem_bookings, (0)::bigint) > 0)) THEN 'completed_with_problems'::text
            WHEN ((t.departure_time IS NOT NULL) AND (t.departure_time < now()) AND (t.status = ANY (ARRAY['available'::text, 'booked'::text, 'pending_confirmation'::text, 'in_communication'::text, 'full'::text, 'in_transit'::text]))) THEN 'delayed'::text
            WHEN (t.status = ANY (ARRAY['booked'::text, 'in_transit'::text, 'pending_confirmation'::text, 'in_communication'::text, 'full'::text])) THEN 'in_progress'::text
            WHEN (t.status = 'available'::text) THEN 'scheduled'::text
            ELSE 'other'::text
        END AS classification
   FROM (public.trips t
     LEFT JOIN trip_aggregate ta ON ((ta.trip_id = t.id)));


--
-- TOC entry 410 (class 1259 OID 23113)
-- Name: ads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    image_url text NOT NULL,
    click_url text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 420 (class 1259 OID 35838)
-- Name: app_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_config (
    key text NOT NULL,
    value text NOT NULL
);


--
-- TOC entry 427 (class 1259 OID 49962)
-- Name: app_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    android_min_version text DEFAULT '1.0.0'::text NOT NULL,
    ios_min_version text DEFAULT '1.0.0'::text NOT NULL,
    force_update_message text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    global_message_active boolean DEFAULT false,
    global_message_content text,
    support_whatsapp text,
    app_open boolean DEFAULT true NOT NULL,
    closed_message text,
    closed_message_ar text,
    terms_of_service text,
    terms_of_service_ar text,
    usage_policy text,
    usage_policy_ar text,
    marketing_main_text text,
    marketing_main_text_ar text,
    home_banner_text text,
    home_banner_text_ar text,
    first_launch_popup_active boolean DEFAULT false NOT NULL,
    first_launch_popup_title text,
    first_launch_popup_title_ar text,
    first_launch_popup_body text,
    first_launch_popup_body_ar text,
    first_launch_popup_image_url text,
    first_launch_popup_action_url text,
    first_launch_popup_target text DEFAULT 'all'::text NOT NULL,
    first_launch_popup_version integer DEFAULT 1 NOT NULL,
    occasional_popup_active boolean DEFAULT false NOT NULL,
    occasional_popup_title text,
    occasional_popup_title_ar text,
    occasional_popup_body text,
    occasional_popup_body_ar text,
    occasional_popup_image_url text,
    occasional_popup_action_url text,
    occasional_popup_target text DEFAULT 'all'::text NOT NULL,
    occasional_popup_published_at timestamp with time zone,
    CONSTRAINT app_settings_occasional_popup_target_check CHECK ((occasional_popup_target = ANY (ARRAY['all'::text, 'individuals'::text, 'drivers'::text, 'companies'::text, 'new_users'::text])))
);


--
-- TOC entry 5675 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN app_settings.app_open; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.app_settings.app_open IS 'Master switch: when false, the mobile app shows the closed/maintenance screen.';


--
-- TOC entry 5676 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN app_settings.occasional_popup_active; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.app_settings.occasional_popup_active IS 'Whether the occasional popup is currently active';


--
-- TOC entry 5677 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN app_settings.occasional_popup_target; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.app_settings.occasional_popup_target IS 'Target audience: all, individuals, drivers, companies, or new_users';


--
-- TOC entry 5678 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN app_settings.occasional_popup_published_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.app_settings.occasional_popup_published_at IS 'Timestamp when the popup was last published. Users track this to show popup once per publish.';


--
-- TOC entry 428 (class 1259 OID 52430)
-- Name: audit_logs_v2; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs_v2 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid,
    action_type text NOT NULL,
    entity_name text NOT NULL,
    entity_id uuid NOT NULL,
    data_before jsonb,
    data_after jsonb,
    ip_address inet,
    user_agent text,
    device_fingerprint text,
    checksum text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 435 (class 1259 OID 52584)
-- Name: blacklist; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blacklist (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    identifier_hash text NOT NULL,
    identifier_type text NOT NULL,
    reason text,
    created_at timestamp with time zone DEFAULT now(),
    admin_id uuid
);


--
-- TOC entry 407 (class 1259 OID 20254)
-- Name: blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blocks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    blocker_id uuid NOT NULL,
    blocked_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT blocks_no_self_block CHECK ((blocker_id <> blocked_id))
);


--
-- TOC entry 453 (class 1259 OID 94301)
-- Name: delivery_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delivery_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booking_id uuid,
    code text NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT delivery_codes_check CHECK ((booking_id IS NOT NULL))
);


--
-- TOC entry 438 (class 1259 OID 52642)
-- Name: export_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.export_jobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid,
    table_name text NOT NULL,
    filter_config jsonb,
    status text DEFAULT 'queued'::text,
    file_url text,
    error_message text,
    record_count integer,
    created_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone,
    CONSTRAINT export_jobs_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'processing'::text, 'completed'::text, 'failed'::text])))
);


--
-- TOC entry 408 (class 1259 OID 22854)
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    country_name_ar text NOT NULL,
    country_name_en text NOT NULL,
    province_name_ar text NOT NULL,
    province_name_en text NOT NULL,
    city_name_ar text NOT NULL,
    city_name_en text NOT NULL,
    town_name_ar text,
    town_name_en text,
    latitude double precision,
    longitude double precision,
    created_at timestamp with time zone DEFAULT now(),
    is_active boolean DEFAULT true NOT NULL,
    country_code text
);


--
-- TOC entry 405 (class 1259 OID 20213)
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booking_id uuid,
    sender_id uuid NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    type text DEFAULT 'text'::text,
    metadata jsonb DEFAULT '{}'::jsonb
);


--
-- TOC entry 411 (class 1259 OID 27720)
-- Name: notification_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    platform text DEFAULT 'unknown'::text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 412 (class 1259 OID 27737)
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    data jsonb,
    is_read boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    idempotency_key character varying(255)
);


--
-- TOC entry 403 (class 1259 OID 19029)
-- Name: ratings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ratings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    rater_id uuid NOT NULL,
    rated_id uuid NOT NULL,
    role_rated public.rating_role NOT NULL,
    rating integer NOT NULL,
    comment text,
    comment_status text DEFAULT 'pending'::text,
    booking_id uuid,
    CONSTRAINT ratings_comment_status_check CHECK ((comment_status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text]))),
    CONSTRAINT ratings_rater_rated_role_check CHECK ((rater_id <> rated_id)),
    CONSTRAINT ratings_rating_check CHECK (((rating >= 1) AND (rating <= 5))),
    CONSTRAINT ratings_score_check CHECK (((rating >= 1) AND (rating <= 5)))
);


--
-- TOC entry 406 (class 1259 OID 20235)
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reporter_id uuid NOT NULL,
    reported_id uuid NOT NULL,
    reason text NOT NULL,
    comment text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    resolved_by uuid,
    resolved_at timestamp with time zone,
    admin_notes text,
    escalation_level text DEFAULT 'support'::text,
    internal_comments jsonb DEFAULT '[]'::jsonb,
    resolution_action text,
    deleted_at timestamp with time zone,
    target_type text DEFAULT 'user'::text NOT NULL,
    target_rating_id uuid,
    target_trip_id uuid,
    CONSTRAINT reports_no_self_report CHECK ((reporter_id <> reported_id)),
    CONSTRAINT reports_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'reviewing'::text, 'resolved'::text, 'dismissed'::text])))
);


--
-- TOC entry 5679 (class 0 OID 0)
-- Dependencies: 406
-- Name: COLUMN reports.target_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reports.target_type IS 'Type of entity being reported: user | driver | rating | trip.';


--
-- TOC entry 430 (class 1259 OID 52501)
-- Name: risk_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.risk_config (
    key text NOT NULL,
    weight integer NOT NULL,
    description text
);


--
-- TOC entry 432 (class 1259 OID 52524)
-- Name: risk_score_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.risk_score_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    old_score integer,
    new_score integer,
    reason text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- TOC entry 437 (class 1259 OID 52626)
-- Name: saved_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saved_filters (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid,
    table_name text NOT NULL,
    filter_name text NOT NULL,
    filter_config jsonb NOT NULL,
    is_public boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- TOC entry 423 (class 1259 OID 39463)
-- Name: scheduled_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scheduled_notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    data jsonb DEFAULT '{}'::jsonb,
    target_type text DEFAULT 'broadcast'::text NOT NULL,
    target_filter jsonb DEFAULT '{}'::jsonb,
    target_user_id uuid,
    scheduled_at timestamp with time zone NOT NULL,
    sent_at timestamp with time zone,
    status text DEFAULT 'pending'::text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT scheduled_notifications_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'cancelled'::text, 'failed'::text]))),
    CONSTRAINT scheduled_notifications_target_type_check CHECK ((target_type = ANY (ARRAY['broadcast'::text, 'segment'::text, 'user'::text])))
);


--
-- TOC entry 425 (class 1259 OID 39607)
-- Name: support_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid NOT NULL,
    sender_id uuid NOT NULL,
    sender_role text DEFAULT 'user'::text NOT NULL,
    content text NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT support_messages_sender_role_check CHECK ((sender_role = ANY (ARRAY['user'::text, 'admin'::text])))
);


--
-- TOC entry 424 (class 1259 OID 39585)
-- Name: support_tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_tickets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    subject text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_by uuid,
    resolved_at timestamp with time zone,
    CONSTRAINT support_tickets_status_check CHECK ((status = ANY (ARRAY['open'::text, 'resolved'::text, 'ignored'::text])))
);


--
-- TOC entry 429 (class 1259 OID 52477)
-- Name: user_restrictions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_restrictions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    restriction_type text NOT NULL,
    reason text NOT NULL,
    expires_at timestamp with time zone,
    admin_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- TOC entry 431 (class 1259 OID 52508)
-- Name: user_risk_scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_risk_scores (
    user_id uuid NOT NULL,
    risk_score integer DEFAULT 100,
    restriction_tier text DEFAULT 'none'::text,
    last_recalculated_at timestamp with time zone DEFAULT now(),
    auto_restricted_at timestamp with time zone,
    CONSTRAINT user_risk_scores_risk_score_check CHECK (((risk_score >= 0) AND (risk_score <= 100)))
);


--
-- TOC entry 402 (class 1259 OID 18999)
-- Name: vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicles (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    owner_id uuid NOT NULL,
    make text,
    model text,
    year integer,
    plate_number text,
    vehicle_photo_url text,
    registration_doc_url text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    vehicle_type text,
    vehicle_photo_url_pending text,
    registration_doc_url_pending text,
    vehicle_color text
);


--
-- TOC entry 455 (class 1259 OID 94383)
-- Name: vehicles_public; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vehicles_public WITH (security_invoker='false') AS
 SELECT id,
    owner_id,
    make,
    model,
    year,
    vehicle_type,
    vehicle_color,
    vehicle_photo_url
   FROM public.vehicles;


--
-- TOC entry 433 (class 1259 OID 52546)
-- Name: verification_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verification_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    document_type text NOT NULL,
    document_url text NOT NULL,
    status text DEFAULT 'pending_review'::text,
    rejection_reason text,
    version integer DEFAULT 1,
    admin_id uuid,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- TOC entry 434 (class 1259 OID 52569)
-- Name: verification_workflow; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verification_workflow (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    entity_type text NOT NULL,
    current_step text DEFAULT 'review'::text,
    approvals_required integer DEFAULT 1,
    approvals_count integer DEFAULT 0,
    approver_ids uuid[] DEFAULT '{}'::uuid[],
    is_fraud_flagged boolean DEFAULT false,
    fraud_notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- TOC entry 439 (class 1259 OID 52768)
-- Name: vm_platform_overview; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.vm_platform_overview AS
 SELECT ( SELECT count(*) AS count
           FROM public.profiles) AS total_users,
    ( SELECT count(*) AS count
           FROM public.bookings
          WHERE (bookings.status = 'pending'::text)) AS active_bookings,
    ( SELECT count(*) AS count
           FROM public.bookings
          WHERE (bookings.status = 'disputed'::text)) AS active_disputes,
    ( SELECT count(*) AS count
           FROM public.reports
          WHERE (reports.status = 'pending'::text)) AS open_reports,
    now() AS last_refreshed_at
  WITH NO DATA;


--
-- TOC entry 5176 (class 2606 OID 39382)
-- Name: admin_audit_log admin_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_audit_log
    ADD CONSTRAINT admin_audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 5232 (class 2606 OID 93374)
-- Name: admin_login_events admin_login_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_login_events
    ADD CONSTRAINT admin_login_events_pkey PRIMARY KEY (id);


--
-- TOC entry 5217 (class 2606 OID 52620)
-- Name: admin_preferences admin_preferences_admin_id_table_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_preferences
    ADD CONSTRAINT admin_preferences_admin_id_table_name_key UNIQUE (admin_id, table_name);


--
-- TOC entry 5219 (class 2606 OID 52618)
-- Name: admin_preferences admin_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_preferences
    ADD CONSTRAINT admin_preferences_pkey PRIMARY KEY (id);


--
-- TOC entry 5144 (class 2606 OID 23122)
-- Name: ads ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id);


--
-- TOC entry 5169 (class 2606 OID 35844)
-- Name: app_config app_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_config
    ADD CONSTRAINT app_config_pkey PRIMARY KEY (key);


--
-- TOC entry 5193 (class 2606 OID 49973)
-- Name: app_settings app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 5196 (class 2606 OID 52438)
-- Name: audit_logs_v2 audit_logs_v2_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs_v2
    ADD CONSTRAINT audit_logs_v2_pkey PRIMARY KEY (id);


--
-- TOC entry 5213 (class 2606 OID 52594)
-- Name: blacklist blacklist_identifier_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blacklist
    ADD CONSTRAINT blacklist_identifier_hash_key UNIQUE (identifier_hash);


--
-- TOC entry 5215 (class 2606 OID 52592)
-- Name: blacklist blacklist_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blacklist
    ADD CONSTRAINT blacklist_pkey PRIMARY KEY (id);


--
-- TOC entry 5119 (class 2606 OID 20262)
-- Name: blocks blocks_blocker_id_blocked_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT blocks_blocker_id_blocked_id_key UNIQUE (blocker_id, blocked_id);


--
-- TOC entry 5121 (class 2606 OID 20260)
-- Name: blocks blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT blocks_pkey PRIMARY KEY (id);


--
-- TOC entry 5123 (class 2606 OID 39416)
-- Name: blocks blocks_unique_pair; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT blocks_unique_pair UNIQUE (blocker_id, blocked_id);


--
-- TOC entry 5096 (class 2606 OID 20198)
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- TOC entry 5236 (class 2606 OID 94315)
-- Name: delivery_codes delivery_codes_booking_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_codes
    ADD CONSTRAINT delivery_codes_booking_id_key UNIQUE (booking_id);


--
-- TOC entry 5238 (class 2606 OID 94311)
-- Name: delivery_codes delivery_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_codes
    ADD CONSTRAINT delivery_codes_pkey PRIMARY KEY (id);


--
-- TOC entry 5223 (class 2606 OID 52651)
-- Name: export_jobs export_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.export_jobs
    ADD CONSTRAINT export_jobs_pkey PRIMARY KEY (id);


--
-- TOC entry 5131 (class 2606 OID 22862)
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- TOC entry 5109 (class 2606 OID 20221)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- TOC entry 5148 (class 2606 OID 27729)
-- Name: notification_tokens notification_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_tokens
    ADD CONSTRAINT notification_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 5151 (class 2606 OID 39418)
-- Name: notification_tokens notification_tokens_unique_user_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_tokens
    ADD CONSTRAINT notification_tokens_unique_user_token UNIQUE (user_id, token);


--
-- TOC entry 5161 (class 2606 OID 27746)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 5067 (class 2606 OID 18853)
-- Name: profiles profiles_phone_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_phone_number_key UNIQUE (phone_number);


--
-- TOC entry 5069 (class 2606 OID 18851)
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- TOC entry 5094 (class 2606 OID 19039)
-- Name: ratings ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_pkey PRIMARY KEY (id);


--
-- TOC entry 5114 (class 2606 OID 20243)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- TOC entry 5201 (class 2606 OID 52507)
-- Name: risk_config risk_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_config
    ADD CONSTRAINT risk_config_pkey PRIMARY KEY (key);


--
-- TOC entry 5207 (class 2606 OID 52532)
-- Name: risk_score_history risk_score_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_score_history
    ADD CONSTRAINT risk_score_history_pkey PRIMARY KEY (id);


--
-- TOC entry 5166 (class 2606 OID 31337)
-- Name: route_alerts route_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_alerts
    ADD CONSTRAINT route_alerts_pkey PRIMARY KEY (id);


--
-- TOC entry 5221 (class 2606 OID 52636)
-- Name: saved_filters saved_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_filters
    ADD CONSTRAINT saved_filters_pkey PRIMARY KEY (id);


--
-- TOC entry 5184 (class 2606 OID 39477)
-- Name: scheduled_notifications scheduled_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_notifications
    ADD CONSTRAINT scheduled_notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 5191 (class 2606 OID 39618)
-- Name: support_messages support_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_messages
    ADD CONSTRAINT support_messages_pkey PRIMARY KEY (id);


--
-- TOC entry 5188 (class 2606 OID 39596)
-- Name: support_tickets support_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_pkey PRIMARY KEY (id);


--
-- TOC entry 5142 (class 2606 OID 23079)
-- Name: trips trips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_pkey PRIMARY KEY (id);


--
-- TOC entry 5154 (class 2606 OID 52264)
-- Name: notification_tokens unique_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_tokens
    ADD CONSTRAINT unique_token UNIQUE (token);


--
-- TOC entry 5199 (class 2606 OID 52485)
-- Name: user_restrictions user_restrictions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_restrictions
    ADD CONSTRAINT user_restrictions_pkey PRIMARY KEY (id);


--
-- TOC entry 5204 (class 2606 OID 52518)
-- Name: user_risk_scores user_risk_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_risk_scores
    ADD CONSTRAINT user_risk_scores_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5084 (class 2606 OID 19008)
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- TOC entry 5086 (class 2606 OID 39420)
-- Name: vehicles vehicles_unique_plate; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_unique_plate UNIQUE (plate_number);


--
-- TOC entry 5209 (class 2606 OID 52558)
-- Name: verification_documents verification_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verification_documents
    ADD CONSTRAINT verification_documents_pkey PRIMARY KEY (id);


--
-- TOC entry 5211 (class 2606 OID 52583)
-- Name: verification_workflow verification_workflow_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verification_workflow
    ADD CONSTRAINT verification_workflow_pkey PRIMARY KEY (id);


--
-- TOC entry 5177 (class 1259 OID 52762)
-- Name: idx_admin_audit_log_created_at_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_audit_log_created_at_desc ON public.admin_audit_log USING btree (created_at DESC);


--
-- TOC entry 5178 (class 1259 OID 52763)
-- Name: idx_admin_audit_log_target_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_audit_log_target_search ON public.admin_audit_log USING btree (target_id, target_type);


--
-- TOC entry 5233 (class 1259 OID 93380)
-- Name: idx_admin_login_events_admin_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_login_events_admin_created ON public.admin_login_events USING btree (admin_id, created_at DESC);


--
-- TOC entry 5234 (class 1259 OID 93401)
-- Name: idx_admin_login_events_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_login_events_event_type ON public.admin_login_events USING btree (event_type, created_at DESC);


--
-- TOC entry 5145 (class 1259 OID 39553)
-- Name: idx_ads_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ads_active ON public.ads USING btree (is_active) WHERE (is_active = true);


--
-- TOC entry 5194 (class 1259 OID 93412)
-- Name: idx_app_settings_occasional_popup_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_app_settings_occasional_popup_published ON public.app_settings USING btree (occasional_popup_published_at DESC) WHERE (occasional_popup_active = true);


--
-- TOC entry 5179 (class 1259 OID 39388)
-- Name: idx_audit_log_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_admin ON public.admin_audit_log USING btree (admin_id);


--
-- TOC entry 5180 (class 1259 OID 39389)
-- Name: idx_audit_log_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_created ON public.admin_audit_log USING btree (created_at DESC);


--
-- TOC entry 5181 (class 1259 OID 39390)
-- Name: idx_audit_log_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_target ON public.admin_audit_log USING btree (target_type, target_id);


--
-- TOC entry 5124 (class 1259 OID 39537)
-- Name: idx_blocks_blocked_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_blocks_blocked_id ON public.blocks USING btree (blocked_id);


--
-- TOC entry 5125 (class 1259 OID 52316)
-- Name: idx_blocks_blocker_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_blocks_blocker_id ON public.blocks USING btree (blocker_id);


--
-- TOC entry 5097 (class 1259 OID 39549)
-- Name: idx_bookings_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bookings_created_at ON public.bookings USING btree (created_at DESC);


--
-- TOC entry 5098 (class 1259 OID 24356)
-- Name: idx_bookings_requester_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bookings_requester_id ON public.bookings USING btree (requester_id);


--
-- TOC entry 5099 (class 1259 OID 26582)
-- Name: idx_bookings_requester_trip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bookings_requester_trip ON public.bookings USING btree (requester_id, trip_id) WHERE (trip_id IS NOT NULL);


--
-- TOC entry 5100 (class 1259 OID 39434)
-- Name: idx_bookings_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bookings_status ON public.bookings USING btree (status);


--
-- TOC entry 5101 (class 1259 OID 39435)
-- Name: idx_bookings_traveler_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bookings_traveler_id ON public.bookings USING btree (traveler_id);


--
-- TOC entry 5102 (class 1259 OID 39436)
-- Name: idx_bookings_trip_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bookings_trip_id ON public.bookings USING btree (trip_id);


--
-- TOC entry 5224 (class 1259 OID 52767)
-- Name: idx_export_jobs_admin_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_export_jobs_admin_status ON public.export_jobs USING btree (admin_id, status);


--
-- TOC entry 5126 (class 1259 OID 39445)
-- Name: idx_locations_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_locations_active ON public.locations USING btree (is_active) WHERE (is_active = true);


--
-- TOC entry 5127 (class 1259 OID 39554)
-- Name: idx_locations_province_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_locations_province_city ON public.locations USING btree (province_name_en, city_name_en);


--
-- TOC entry 5103 (class 1259 OID 39550)
-- Name: idx_messages_booking_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_booking_created ON public.messages USING btree (booking_id, created_at DESC);


--
-- TOC entry 5104 (class 1259 OID 39438)
-- Name: idx_messages_booking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_booking_id ON public.messages USING btree (booking_id);


--
-- TOC entry 5105 (class 1259 OID 39439)
-- Name: idx_messages_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_created_at ON public.messages USING btree (created_at DESC);


--
-- TOC entry 5107 (class 1259 OID 39538)
-- Name: idx_messages_sender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_sender_id ON public.messages USING btree (sender_id);


--
-- TOC entry 5146 (class 1259 OID 52315)
-- Name: idx_notification_tokens_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_tokens_user_id ON public.notification_tokens USING btree (user_id);


--
-- TOC entry 5155 (class 1259 OID 39447)
-- Name: idx_notifications_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_created ON public.notifications USING btree (created_at DESC);


--
-- TOC entry 5156 (class 1259 OID 94352)
-- Name: idx_notifications_idempotency; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_notifications_idempotency ON public.notifications USING btree (idempotency_key);


--
-- TOC entry 5157 (class 1259 OID 39446)
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id);


--
-- TOC entry 5158 (class 1259 OID 52314)
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- TOC entry 5159 (class 1259 OID 39548)
-- Name: idx_notifications_user_unread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_unread ON public.notifications USING btree (user_id, is_read) WHERE (is_read = false);


--
-- TOC entry 5058 (class 1259 OID 52760)
-- Name: idx_profiles_full_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_full_name_trgm ON public.profiles USING gin (full_name public.gin_trgm_ops);


--
-- TOC entry 5059 (class 1259 OID 39428)
-- Name: idx_profiles_is_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_is_admin ON public.profiles USING btree (is_admin) WHERE (is_admin = true);


--
-- TOC entry 5060 (class 1259 OID 52761)
-- Name: idx_profiles_phone_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_phone_trgm ON public.profiles USING gin (phone_number public.gin_trgm_ops);


--
-- TOC entry 5061 (class 1259 OID 39552)
-- Name: idx_profiles_suspended; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_suspended ON public.profiles USING btree (is_suspended) WHERE (is_suspended = true);


--
-- TOC entry 5062 (class 1259 OID 39425)
-- Name: idx_profiles_traveler_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_traveler_status ON public.profiles USING btree (traveler_status);


--
-- TOC entry 5087 (class 1259 OID 29079)
-- Name: idx_ratings_booking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ratings_booking_id ON public.ratings USING btree (booking_id);


--
-- TOC entry 5088 (class 1259 OID 39547)
-- Name: idx_ratings_comment_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ratings_comment_status ON public.ratings USING btree (comment_status) WHERE (comment_status = 'pending'::text);


--
-- TOC entry 5090 (class 1259 OID 39440)
-- Name: idx_ratings_rated_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ratings_rated_id ON public.ratings USING btree (rated_id);


--
-- TOC entry 5091 (class 1259 OID 39546)
-- Name: idx_ratings_rated_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ratings_rated_role ON public.ratings USING btree (rated_id, role_rated);


--
-- TOC entry 5092 (class 1259 OID 39441)
-- Name: idx_ratings_rater_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ratings_rater_id ON public.ratings USING btree (rater_id);


--
-- TOC entry 5110 (class 1259 OID 39443)
-- Name: idx_reports_reported_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reports_reported_id ON public.reports USING btree (reported_id);


--
-- TOC entry 5111 (class 1259 OID 39539)
-- Name: idx_reports_reporter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reports_reporter_id ON public.reports USING btree (reporter_id);


--
-- TOC entry 5112 (class 1259 OID 39442)
-- Name: idx_reports_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reports_status ON public.reports USING btree (status);


--
-- TOC entry 5205 (class 1259 OID 52766)
-- Name: idx_risk_score_history_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_risk_score_history_user_id ON public.risk_score_history USING btree (user_id);


--
-- TOC entry 5163 (class 1259 OID 39541)
-- Name: idx_route_alerts_dest_loc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_route_alerts_dest_loc ON public.route_alerts USING btree (dest_location_id);


--
-- TOC entry 5164 (class 1259 OID 39540)
-- Name: idx_route_alerts_origin_loc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_route_alerts_origin_loc ON public.route_alerts USING btree (origin_location_id);


--
-- TOC entry 5182 (class 1259 OID 39489)
-- Name: idx_scheduled_notifications_status_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scheduled_notifications_status_time ON public.scheduled_notifications USING btree (status, scheduled_at) WHERE (status = 'pending'::text);


--
-- TOC entry 5189 (class 1259 OID 39631)
-- Name: idx_support_messages_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_messages_ticket_id ON public.support_messages USING btree (ticket_id, created_at);


--
-- TOC entry 5185 (class 1259 OID 39630)
-- Name: idx_support_tickets_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_tickets_status ON public.support_tickets USING btree (status);


--
-- TOC entry 5186 (class 1259 OID 39629)
-- Name: idx_support_tickets_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_support_tickets_user_id ON public.support_tickets USING btree (user_id);


--
-- TOC entry 5132 (class 1259 OID 39429)
-- Name: idx_trips_departure_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trips_departure_time ON public.trips USING btree (departure_time);


--
-- TOC entry 5133 (class 1259 OID 52313)
-- Name: idx_trips_dest_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trips_dest_location ON public.trips USING btree (dest_location_id);


--
-- TOC entry 5134 (class 1259 OID 49959)
-- Name: idx_trips_locations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trips_locations ON public.trips USING btree (origin_location_id, dest_location_id);


--
-- TOC entry 5135 (class 1259 OID 52312)
-- Name: idx_trips_origin_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trips_origin_location ON public.trips USING btree (origin_location_id);


--
-- TOC entry 5136 (class 1259 OID 26583)
-- Name: idx_trips_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trips_status ON public.trips USING btree (status);


--
-- TOC entry 5137 (class 1259 OID 39551)
-- Name: idx_trips_status_departure; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trips_status_departure ON public.trips USING btree (status, departure_time) WHERE (status = 'available'::text);


--
-- TOC entry 5138 (class 1259 OID 39430)
-- Name: idx_trips_traveler_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trips_traveler_id ON public.trips USING btree (traveler_id);


--
-- TOC entry 5197 (class 1259 OID 52764)
-- Name: idx_user_restrictions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_restrictions_user_id ON public.user_restrictions USING btree (user_id);


--
-- TOC entry 5202 (class 1259 OID 52765)
-- Name: idx_user_risk_scores_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_risk_scores_user_id ON public.user_risk_scores USING btree (user_id);


--
-- TOC entry 5081 (class 1259 OID 39444)
-- Name: idx_vehicles_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vehicles_owner ON public.vehicles USING btree (owner_id);


--
-- TOC entry 5082 (class 1259 OID 52317)
-- Name: idx_vehicles_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vehicles_owner_id ON public.vehicles USING btree (owner_id);


--
-- TOC entry 5225 (class 1259 OID 52776)
-- Name: idx_vm_platform_overview_refresh; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_vm_platform_overview_refresh ON public.vm_platform_overview USING btree (last_refreshed_at);


--
-- TOC entry 5128 (class 1259 OID 23099)
-- Name: locations_country_ar_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_country_ar_idx ON public.locations USING btree (country_name_ar);


--
-- TOC entry 5129 (class 1259 OID 23100)
-- Name: locations_country_en_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_country_en_idx ON public.locations USING btree (country_name_en);


--
-- TOC entry 5149 (class 1259 OID 27735)
-- Name: notification_tokens_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX notification_tokens_token_key ON public.notification_tokens USING btree (token);


--
-- TOC entry 5152 (class 1259 OID 27736)
-- Name: notification_tokens_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notification_tokens_user_idx ON public.notification_tokens USING btree (user_id);


--
-- TOC entry 5162 (class 1259 OID 27752)
-- Name: notifications_user_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_user_created_idx ON public.notifications USING btree (user_id, created_at DESC);


--
-- TOC entry 5063 (class 1259 OID 92825)
-- Name: profiles_is_blocked_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profiles_is_blocked_idx ON public.profiles USING btree (is_blocked) WHERE (is_blocked = true);


--
-- TOC entry 5064 (class 1259 OID 92824)
-- Name: profiles_is_featured_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profiles_is_featured_idx ON public.profiles USING btree (is_featured) WHERE (is_featured = true);


--
-- TOC entry 5065 (class 1259 OID 92823)
-- Name: profiles_is_trusted_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profiles_is_trusted_idx ON public.profiles USING btree (is_trusted) WHERE (is_trusted = true);


--
-- TOC entry 5115 (class 1259 OID 92858)
-- Name: reports_target_rating_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reports_target_rating_id_idx ON public.reports USING btree (target_rating_id);


--
-- TOC entry 5117 (class 1259 OID 92856)
-- Name: reports_target_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reports_target_type_idx ON public.reports USING btree (target_type);


--
-- TOC entry 5167 (class 1259 OID 35858)
-- Name: route_alerts_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX route_alerts_user_id_idx ON public.route_alerts USING btree (user_id);


--
-- TOC entry 5139 (class 1259 OID 23096)
-- Name: trips_dest_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trips_dest_id_idx ON public.trips USING btree (dest_location_id);


--
-- TOC entry 5140 (class 1259 OID 23095)
-- Name: trips_origin_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trips_origin_id_idx ON public.trips USING btree (origin_location_id);


--
-- TOC entry 5340 (class 2620 OID 52451)
-- Name: app_config audit_trigger_app_config; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_app_config AFTER INSERT OR DELETE OR UPDATE ON public.app_config FOR EACH ROW EXECUTE FUNCTION public.proc_universal_audit();


--
-- TOC entry 5343 (class 2620 OID 52452)
-- Name: app_settings audit_trigger_app_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_app_settings AFTER INSERT OR DELETE OR UPDATE ON public.app_settings FOR EACH ROW EXECUTE FUNCTION public.proc_universal_audit();


--
-- TOC entry 5324 (class 2620 OID 52455)
-- Name: bookings audit_trigger_bookings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_bookings AFTER INSERT OR DELETE OR UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.proc_universal_audit();


--
-- TOC entry 5305 (class 2620 OID 52449)
-- Name: profiles audit_trigger_profiles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_profiles AFTER INSERT OR DELETE OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.proc_universal_audit();


--
-- TOC entry 5335 (class 2620 OID 52453)
-- Name: trips audit_trigger_trips; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_trips AFTER INSERT OR DELETE OR UPDATE ON public.trips FOR EACH ROW EXECUTE FUNCTION public.proc_universal_audit();


--
-- TOC entry 5325 (class 2620 OID 55371)
-- Name: bookings booking_fsm_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER booking_fsm_guard BEFORE UPDATE OF status ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.enforce_booking_state_machine();


--
-- TOC entry 5339 (class 2620 OID 29061)
-- Name: notifications on_notification_created; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_notification_created AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.handle_new_notification();


--
-- TOC entry 5322 (class 2620 OID 20279)
-- Name: ratings on_rating_added; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_rating_added AFTER INSERT OR UPDATE ON public.ratings FOR EACH ROW EXECUTE FUNCTION public.handle_new_rating();


--
-- TOC entry 5323 (class 2620 OID 39452)
-- Name: ratings on_rating_change; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_rating_change AFTER INSERT OR DELETE OR UPDATE ON public.ratings FOR EACH ROW EXECUTE FUNCTION public.update_rating_averages();


--
-- TOC entry 5336 (class 2620 OID 35837)
-- Name: trips on_trip_created_notify_alerts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_trip_created_notify_alerts AFTER INSERT ON public.trips FOR EACH ROW EXECUTE FUNCTION public.notify_matching_alerts();


--
-- TOC entry 5306 (class 2620 OID 39324)
-- Name: profiles protect_profile_admin_columns; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER protect_profile_admin_columns BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.protect_admin_columns();


--
-- TOC entry 5341 (class 2620 OID 93361)
-- Name: support_messages support_messages_touch_ticket_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER support_messages_touch_ticket_updated_at AFTER INSERT ON public.support_messages FOR EACH ROW EXECUTE FUNCTION public.touch_support_ticket_updated_at();


--
-- TOC entry 5338 (class 2620 OID 93286)
-- Name: ads trg_ads_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_ads_set_updated_at BEFORE UPDATE ON public.ads FOR EACH ROW EXECUTE FUNCTION public.fn_set_ads_updated_at();


--
-- TOC entry 5345 (class 2620 OID 52667)
-- Name: blacklist trg_audit_blacklist; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_blacklist AFTER INSERT OR DELETE ON public.blacklist FOR EACH ROW EXECUTE FUNCTION public.fn_audit_log_v2();


--
-- TOC entry 5326 (class 2620 OID 52666)
-- Name: bookings trg_audit_bookings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_bookings AFTER DELETE OR UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.fn_audit_log_v2();


--
-- TOC entry 5307 (class 2620 OID 52664)
-- Name: profiles trg_audit_profiles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_audit_profiles AFTER INSERT OR DELETE OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.fn_audit_log_v2();


--
-- TOC entry 5327 (class 2620 OID 61093)
-- Name: bookings trg_auto_mark_trip_full; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auto_mark_trip_full AFTER UPDATE OF status ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.fn_auto_mark_trip_full();


--
-- TOC entry 5328 (class 2620 OID 52670)
-- Name: bookings trg_booking_integrity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_booking_integrity BEFORE UPDATE OF status ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.fn_enforce_booking_integrity();


--
-- TOC entry 5329 (class 2620 OID 94330)
-- Name: bookings trg_generate_booking_delivery_code; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_generate_booking_delivery_code AFTER INSERT ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.fn_generate_booking_delivery_code();


--
-- TOC entry 5330 (class 2620 OID 94342)
-- Name: bookings trg_guard_bookings_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_guard_bookings_insert BEFORE INSERT ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.fn_guard_bookings_insert();


--
-- TOC entry 5331 (class 2620 OID 94340)
-- Name: bookings trg_guard_bookings_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_guard_bookings_update BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.fn_guard_bookings_update();


--
-- TOC entry 5337 (class 2620 OID 94344)
-- Name: trips trg_guard_trips_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_guard_trips_update BEFORE UPDATE ON public.trips FOR EACH ROW EXECUTE FUNCTION public.fn_guard_trips_update();


--
-- TOC entry 5308 (class 2620 OID 52676)
-- Name: profiles trg_handle_expiry_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_handle_expiry_update BEFORE UPDATE OF identity_expiry ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.fn_handle_expiry_update();


--
-- TOC entry 5309 (class 2620 OID 52542)
-- Name: profiles trg_profile_risk_sync; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_profile_risk_sync AFTER UPDATE OF strike_count, is_suspended, deleted_at ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.fn_sync_user_risk_score();


--
-- TOC entry 5310 (class 2620 OID 93060)
-- Name: profiles trg_protect_profile_metadata; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_protect_profile_metadata BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.protect_profile_metadata();


--
-- TOC entry 5334 (class 2620 OID 52544)
-- Name: reports trg_report_risk_sync; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_report_risk_sync AFTER UPDATE OF status ON public.reports FOR EACH ROW EXECUTE FUNCTION public.fn_report_risk_sync();


--
-- TOC entry 5342 (class 2620 OID 39633)
-- Name: support_messages trg_support_message_update_ticket; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_support_message_update_ticket AFTER INSERT ON public.support_messages FOR EACH ROW EXECUTE FUNCTION public.update_ticket_on_new_message();


--
-- TOC entry 5344 (class 2620 OID 52678)
-- Name: verification_workflow trg_sync_approvals_count; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sync_approvals_count BEFORE INSERT OR UPDATE OF approver_ids ON public.verification_workflow FOR EACH ROW EXECUTE FUNCTION public.fn_sync_approvals_count();


--
-- TOC entry 5332 (class 2620 OID 52500)
-- Name: bookings trg_sync_dispute_notes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sync_dispute_notes BEFORE UPDATE OF dispute_outcome ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.sync_dispute_notes();


--
-- TOC entry 5316 (class 2620 OID 45262)
-- Name: vehicles trg_sync_is_driver_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sync_is_driver_delete AFTER DELETE ON public.vehicles FOR EACH ROW EXECUTE FUNCTION public.sync_is_driver();


--
-- TOC entry 5317 (class 2620 OID 45261)
-- Name: vehicles trg_sync_is_driver_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sync_is_driver_insert AFTER INSERT ON public.vehicles FOR EACH ROW EXECUTE FUNCTION public.sync_is_driver();


--
-- TOC entry 5333 (class 2620 OID 55370)
-- Name: bookings trg_sync_trip_load; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sync_trip_load AFTER INSERT OR DELETE OR UPDATE OF status, reserved_weight_kg ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.sync_trip_load();


--
-- TOC entry 5318 (class 2620 OID 39450)
-- Name: vehicles update_vehicles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON public.vehicles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 5319 (class 2620 OID 45276)
-- Name: vehicles vehicles_sync_is_driver_del; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER vehicles_sync_is_driver_del AFTER DELETE ON public.vehicles FOR EACH ROW EXECUTE FUNCTION public.trg_vehicles_sync_is_driver();


--
-- TOC entry 5320 (class 2620 OID 45275)
-- Name: vehicles vehicles_sync_is_driver_ins; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER vehicles_sync_is_driver_ins AFTER INSERT ON public.vehicles FOR EACH ROW EXECUTE FUNCTION public.trg_vehicles_sync_is_driver();


--
-- TOC entry 5321 (class 2620 OID 45277)
-- Name: vehicles vehicles_sync_is_driver_upd; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER vehicles_sync_is_driver_upd AFTER UPDATE OF owner_id ON public.vehicles FOR EACH ROW EXECUTE FUNCTION public.trg_vehicles_sync_is_driver();


--
-- TOC entry 5282 (class 2606 OID 39383)
-- Name: admin_audit_log admin_audit_log_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_audit_log
    ADD CONSTRAINT admin_audit_log_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES auth.users(id);


--
-- TOC entry 5302 (class 2606 OID 93375)
-- Name: admin_login_events admin_login_events_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_login_events
    ADD CONSTRAINT admin_login_events_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- TOC entry 5297 (class 2606 OID 52621)
-- Name: admin_preferences admin_preferences_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_preferences
    ADD CONSTRAINT admin_preferences_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- TOC entry 5289 (class 2606 OID 52439)
-- Name: audit_logs_v2 audit_logs_v2_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs_v2
    ADD CONSTRAINT audit_logs_v2_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.profiles(id);


--
-- TOC entry 5296 (class 2606 OID 52595)
-- Name: blacklist blacklist_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blacklist
    ADD CONSTRAINT blacklist_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.profiles(id);


--
-- TOC entry 5269 (class 2606 OID 61146)
-- Name: blocks blocks_blocked_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT blocks_blocked_id_fkey FOREIGN KEY (blocked_id) REFERENCES public.profiles(id);


--
-- TOC entry 5270 (class 2606 OID 61141)
-- Name: blocks blocks_blocker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT blocks_blocker_id_fkey FOREIGN KEY (blocker_id) REFERENCES public.profiles(id);


--
-- TOC entry 5255 (class 2606 OID 52472)
-- Name: bookings bookings_dispute_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_dispute_resolved_by_fkey FOREIGN KEY (dispute_resolved_by) REFERENCES public.profiles(id);


--
-- TOC entry 5256 (class 2606 OID 24351)
-- Name: bookings bookings_requester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES auth.users(id);


--
-- TOC entry 5257 (class 2606 OID 49925)
-- Name: bookings bookings_requester_id_profiles_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_requester_id_profiles_fkey FOREIGN KEY (requester_id) REFERENCES public.profiles(id);


--
-- TOC entry 5258 (class 2606 OID 20204)
-- Name: bookings bookings_traveler_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_traveler_id_fkey FOREIGN KEY (traveler_id) REFERENCES public.profiles(id);


--
-- TOC entry 5259 (class 2606 OID 23186)
-- Name: bookings bookings_trip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id);


--
-- TOC entry 5303 (class 2606 OID 94321)
-- Name: delivery_codes delivery_codes_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_codes
    ADD CONSTRAINT delivery_codes_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- TOC entry 5299 (class 2606 OID 52652)
-- Name: export_jobs export_jobs_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.export_jobs
    ADD CONSTRAINT export_jobs_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- TOC entry 5260 (class 2606 OID 39560)
-- Name: messages messages_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- TOC entry 5262 (class 2606 OID 20227)
-- Name: messages messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.profiles(id);


--
-- TOC entry 5274 (class 2606 OID 27730)
-- Name: notification_tokens notification_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_tokens
    ADD CONSTRAINT notification_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- TOC entry 5275 (class 2606 OID 27747)
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- TOC entry 5241 (class 2606 OID 92813)
-- Name: profiles profiles_blocked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_blocked_by_fkey FOREIGN KEY (blocked_by) REFERENCES auth.users(id);


--
-- TOC entry 5242 (class 2606 OID 18854)
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id);


--
-- TOC entry 5243 (class 2606 OID 39410)
-- Name: profiles profiles_suspended_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_suspended_by_fkey FOREIGN KEY (suspended_by) REFERENCES auth.users(id);


--
-- TOC entry 5244 (class 2606 OID 92818)
-- Name: profiles profiles_trust_badge_set_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_trust_badge_set_by_fkey FOREIGN KEY (trust_badge_set_by) REFERENCES auth.users(id);


--
-- TOC entry 5251 (class 2606 OID 39575)
-- Name: ratings ratings_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
-- TOC entry 5253 (class 2606 OID 19045)
-- Name: ratings ratings_rated_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_rated_id_fkey FOREIGN KEY (rated_id) REFERENCES public.profiles(id);


--
-- TOC entry 5254 (class 2606 OID 19040)
-- Name: ratings ratings_rater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_rater_id_fkey FOREIGN KEY (rater_id) REFERENCES public.profiles(id);


--
-- TOC entry 5263 (class 2606 OID 20249)
-- Name: reports reports_reported_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_reported_id_fkey FOREIGN KEY (reported_id) REFERENCES public.profiles(id);


--
-- TOC entry 5264 (class 2606 OID 20244)
-- Name: reports reports_reporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(id);


--
-- TOC entry 5265 (class 2606 OID 39404)
-- Name: reports reports_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES auth.users(id);


--
-- TOC entry 5266 (class 2606 OID 92846)
-- Name: reports reports_target_rating_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_target_rating_id_fkey FOREIGN KEY (target_rating_id) REFERENCES public.ratings(id) ON DELETE SET NULL;


--
-- TOC entry 5268 (class 2606 OID 92851)
-- Name: reports reports_target_trip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_target_trip_id_fkey FOREIGN KEY (target_trip_id) REFERENCES public.trips(id) ON DELETE SET NULL;


--
-- TOC entry 5293 (class 2606 OID 52533)
-- Name: risk_score_history risk_score_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_score_history
    ADD CONSTRAINT risk_score_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- TOC entry 5276 (class 2606 OID 31348)
-- Name: route_alerts route_alerts_dest_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_alerts
    ADD CONSTRAINT route_alerts_dest_location_id_fkey FOREIGN KEY (dest_location_id) REFERENCES public.locations(id);


--
-- TOC entry 5277 (class 2606 OID 31343)
-- Name: route_alerts route_alerts_origin_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_alerts
    ADD CONSTRAINT route_alerts_origin_location_id_fkey FOREIGN KEY (origin_location_id) REFERENCES public.locations(id);


--
-- TOC entry 5278 (class 2606 OID 31338)
-- Name: route_alerts route_alerts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_alerts
    ADD CONSTRAINT route_alerts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- TOC entry 5298 (class 2606 OID 52637)
-- Name: saved_filters saved_filters_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saved_filters
    ADD CONSTRAINT saved_filters_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- TOC entry 5283 (class 2606 OID 39483)
-- Name: scheduled_notifications scheduled_notifications_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_notifications
    ADD CONSTRAINT scheduled_notifications_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- TOC entry 5284 (class 2606 OID 39478)
-- Name: scheduled_notifications scheduled_notifications_target_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_notifications
    ADD CONSTRAINT scheduled_notifications_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES auth.users(id);


--
-- TOC entry 5287 (class 2606 OID 39624)
-- Name: support_messages support_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_messages
    ADD CONSTRAINT support_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- TOC entry 5288 (class 2606 OID 39619)
-- Name: support_messages support_messages_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_messages
    ADD CONSTRAINT support_messages_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.support_tickets(id) ON DELETE CASCADE;


--
-- TOC entry 5285 (class 2606 OID 39602)
-- Name: support_tickets support_tickets_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- TOC entry 5286 (class 2606 OID 39597)
-- Name: support_tickets support_tickets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- TOC entry 5271 (class 2606 OID 23108)
-- Name: trips trips_dest_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_dest_location_id_fkey FOREIGN KEY (dest_location_id) REFERENCES public.locations(id);


--
-- TOC entry 5272 (class 2606 OID 23103)
-- Name: trips trips_origin_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_origin_location_id_fkey FOREIGN KEY (origin_location_id) REFERENCES public.locations(id);


--
-- TOC entry 5273 (class 2606 OID 23090)
-- Name: trips trips_traveler_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_traveler_id_fkey FOREIGN KEY (traveler_id) REFERENCES public.profiles(id);


--
-- TOC entry 5290 (class 2606 OID 52491)
-- Name: user_restrictions user_restrictions_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_restrictions
    ADD CONSTRAINT user_restrictions_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.profiles(id);


--
-- TOC entry 5291 (class 2606 OID 52486)
-- Name: user_restrictions user_restrictions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_restrictions
    ADD CONSTRAINT user_restrictions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);


--
-- TOC entry 5292 (class 2606 OID 52519)
-- Name: user_risk_scores user_risk_scores_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_risk_scores
    ADD CONSTRAINT user_risk_scores_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- TOC entry 5250 (class 2606 OID 40816)
-- Name: vehicles vehicles_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- TOC entry 5294 (class 2606 OID 52564)
-- Name: verification_documents verification_documents_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verification_documents
    ADD CONSTRAINT verification_documents_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.profiles(id);


--
-- TOC entry 5295 (class 2606 OID 52559)
-- Name: verification_documents verification_documents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verification_documents
    ADD CONSTRAINT verification_documents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- TOC entry 5625 (class 3256 OID 93064)
-- Name: risk_score_history Admins can read risk score history; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can read risk score history" ON public.risk_score_history FOR SELECT USING ((public.is_admin() OR (auth.uid() = user_id)));


--
-- TOC entry 5622 (class 3256 OID 93061)
-- Name: user_risk_scores Admins can read risk scores; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can read risk scores" ON public.user_risk_scores FOR SELECT USING ((public.is_admin() OR (auth.uid() = user_id)));


--
-- TOC entry 5621 (class 3256 OID 93059)
-- Name: verification_workflow Admins can read verification workflows; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can read verification workflows" ON public.verification_workflow FOR SELECT USING (public.is_admin());


--
-- TOC entry 5545 (class 3256 OID 21589)
-- Name: profiles Admins can update all profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update all profiles" ON public.profiles FOR UPDATE TO authenticated USING (public.is_admin());


--
-- TOC entry 5575 (class 3256 OID 52603)
-- Name: verification_documents Admins can view all verification data; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can view all verification data" ON public.verification_documents FOR SELECT USING (public.is_admin());


--
-- TOC entry 5544 (class 3256 OID 52659)
-- Name: export_jobs Admins manage own export jobs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage own export jobs" ON public.export_jobs USING ((auth.uid() = admin_id));


--
-- TOC entry 5542 (class 3256 OID 52657)
-- Name: admin_preferences Admins manage own preferences; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage own preferences" ON public.admin_preferences USING ((auth.uid() = admin_id));


--
-- TOC entry 5543 (class 3256 OID 52658)
-- Name: saved_filters Admins manage own saved filters; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage own saved filters" ON public.saved_filters USING (((auth.uid() = admin_id) OR ((is_public = true) AND public.is_admin())));


--
-- TOC entry 5559 (class 3256 OID 93280)
-- Name: ads Ads are viewable by everyone.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Ads are viewable by everyone." ON public.ads FOR SELECT USING (((is_active = true) OR public.is_admin()));


--
-- TOC entry 5607 (class 3256 OID 52272)
-- Name: app_config App config is viewable by everyone.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "App config is viewable by everyone." ON public.app_config FOR SELECT USING (true);


--
-- TOC entry 5608 (class 3256 OID 52274)
-- Name: app_settings App settings are viewable by everyone.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "App settings are viewable by everyone." ON public.app_settings FOR SELECT USING (true);


--
-- TOC entry 5552 (class 3256 OID 52444)
-- Name: audit_logs_v2 Audit logs are viewable by admins; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Audit logs are viewable by admins" ON public.audit_logs_v2 FOR SELECT USING (public.is_admin());


--
-- TOC entry 5556 (class 3256 OID 52446)
-- Name: audit_logs_v2 Deny deletes on audit logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Deny deletes on audit logs" ON public.audit_logs_v2 FOR DELETE USING (false);


--
-- TOC entry 5553 (class 3256 OID 52445)
-- Name: audit_logs_v2 Deny updates on audit logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Deny updates on audit logs" ON public.audit_logs_v2 FOR UPDATE USING (false);


--
-- TOC entry 5602 (class 3256 OID 52268)
-- Name: locations Locations are viewable by everyone.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Locations are viewable by everyone." ON public.locations FOR SELECT USING (true);


--
-- TOC entry 5614 (class 3256 OID 52497)
-- Name: user_restrictions Only OpsAdmin+ can manage restrictions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only OpsAdmin+ can manage restrictions" ON public.user_restrictions USING (public.has_role('ops_admin'::public.admin_role));


--
-- TOC entry 5562 (class 3256 OID 93283)
-- Name: ads Only admins can delete ads.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can delete ads." ON public.ads FOR DELETE USING (public.is_admin());


--
-- TOC entry 5560 (class 3256 OID 93281)
-- Name: ads Only admins can insert ads.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can insert ads." ON public.ads FOR INSERT WITH CHECK (public.is_admin());


--
-- TOC entry 5612 (class 3256 OID 52308)
-- Name: scheduled_notifications Only admins can manage scheduled notifications.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can manage scheduled notifications." ON public.scheduled_notifications USING (public.is_admin());


--
-- TOC entry 5604 (class 3256 OID 52269)
-- Name: locations Only admins can modify locations.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can modify locations." ON public.locations USING (public.is_admin());


--
-- TOC entry 5561 (class 3256 OID 93282)
-- Name: ads Only admins can update ads.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can update ads." ON public.ads FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 5579 (class 3256 OID 52605)
-- Name: blacklist Only super_admins can manage blacklist; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only super_admins can manage blacklist" ON public.blacklist USING (public.check_role(ARRAY['super_admin'::public.admin_role]));


--
-- TOC entry 5540 (class 3256 OID 52427)
-- Name: app_config Ops and Super manage config; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Ops and Super manage config" ON public.app_config USING ((public.has_role('ops_admin'::public.admin_role) OR public.has_role('super_admin'::public.admin_role)));


--
-- TOC entry 5541 (class 3256 OID 52428)
-- Name: app_settings Ops and Super manage settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Ops and Super manage settings" ON public.app_settings USING ((public.has_role('ops_admin'::public.admin_role) OR public.has_role('super_admin'::public.admin_role)));


--
-- TOC entry 5631 (class 3256 OID 93068)
-- Name: ratings OpsAdmin+ can delete ratings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "OpsAdmin+ can delete ratings" ON public.ratings FOR DELETE USING (public.has_role('ops_admin'::public.admin_role));


--
-- TOC entry 5628 (class 3256 OID 93065)
-- Name: risk_score_history OpsAdmin+ can insert risk score history; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "OpsAdmin+ can insert risk score history" ON public.risk_score_history FOR INSERT WITH CHECK (public.has_role('ops_admin'::public.admin_role));


--
-- TOC entry 5615 (class 3256 OID 93058)
-- Name: verification_workflow OpsAdmin+ can manage verification workflows; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "OpsAdmin+ can manage verification workflows" ON public.verification_workflow USING (public.has_role('ops_admin'::public.admin_role)) WITH CHECK (public.has_role('ops_admin'::public.admin_role));


--
-- TOC entry 5624 (class 3256 OID 93063)
-- Name: user_risk_scores OpsAdmin+ can update risk scores; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "OpsAdmin+ can update risk scores" ON public.user_risk_scores FOR UPDATE USING (public.has_role('ops_admin'::public.admin_role)) WITH CHECK (public.has_role('ops_admin'::public.admin_role));


--
-- TOC entry 5623 (class 3256 OID 93062)
-- Name: user_risk_scores OpsAdmin+ can write risk scores; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "OpsAdmin+ can write risk scores" ON public.user_risk_scores FOR INSERT WITH CHECK (public.has_role('ops_admin'::public.admin_role));


--
-- TOC entry 5574 (class 3256 OID 52300)
-- Name: vehicles Owners can manage vehicles.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Owners can manage vehicles." ON public.vehicles USING (((auth.uid() = owner_id) OR public.is_admin()));


--
-- TOC entry 5587 (class 3256 OID 52338)
-- Name: profiles Public profiles are viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (((deleted_at IS NULL) OR public.is_admin()));


--
-- TOC entry 5563 (class 3256 OID 52284)
-- Name: ratings Ratings viewable by everyone.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Ratings viewable by everyone." ON public.ratings FOR SELECT USING (true);


--
-- TOC entry 5557 (class 3256 OID 52661)
-- Name: admin_audit_log ReadOnly: Admins can view history; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "ReadOnly: Admins can view history" ON public.admin_audit_log FOR SELECT USING (public.is_admin());


--
-- TOC entry 5613 (class 3256 OID 52496)
-- Name: user_restrictions Restrictions viewable by admins and target user; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Restrictions viewable by admins and target user" ON public.user_restrictions FOR SELECT USING ((public.has_role('support_agent'::public.admin_role) OR (auth.uid() = user_id)));


--
-- TOC entry 5630 (class 3256 OID 93067)
-- Name: ratings SupportAgent+ can update ratings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "SupportAgent+ can update ratings" ON public.ratings FOR UPDATE USING (public.has_role('support_agent'::public.admin_role)) WITH CHECK (public.has_role('support_agent'::public.admin_role));


--
-- TOC entry 5629 (class 3256 OID 93066)
-- Name: reports SupportAgent+ can update reports; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "SupportAgent+ can update reports" ON public.reports FOR UPDATE USING (public.has_role('support_agent'::public.admin_role)) WITH CHECK (public.has_role('support_agent'::public.admin_role));


--
-- TOC entry 5554 (class 3256 OID 93076)
-- Name: notifications SupportAgent+ inserts admin notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "SupportAgent+ inserts admin notifications" ON public.notifications FOR INSERT WITH CHECK (((auth.uid() = user_id) OR public.has_role('support_agent'::public.admin_role)));


--
-- TOC entry 5558 (class 3256 OID 52662)
-- Name: admin_audit_log System: Authorized apps can insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "System: Authorized apps can insert" ON public.admin_audit_log FOR INSERT WITH CHECK ((public.is_admin() OR (auth.role() = 'service_role'::text)));


--
-- TOC entry 5573 (class 3256 OID 52296)
-- Name: trips Trips are viewable by everyone.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Trips are viewable by everyone." ON public.trips FOR SELECT USING (true);


--
-- TOC entry 5565 (class 3256 OID 52289)
-- Name: reports Users can create reports.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create reports." ON public.reports FOR INSERT WITH CHECK ((auth.uid() = reporter_id));


--
-- TOC entry 5611 (class 3256 OID 52278)
-- Name: blocks Users can delete their own blocks.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own blocks." ON public.blocks FOR DELETE USING (((auth.uid() = blocker_id) OR public.is_admin()));


--
-- TOC entry 5610 (class 3256 OID 52277)
-- Name: blocks Users can insert blocks as blocker.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert blocks as blocker." ON public.blocks FOR INSERT WITH CHECK ((auth.uid() = blocker_id));


--
-- TOC entry 5548 (class 3256 OID 52281)
-- Name: messages Users can insert messages to their bookings.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert messages to their bookings." ON public.messages FOR INSERT WITH CHECK (((auth.uid() = sender_id) AND (booking_id IN ( SELECT bookings.id
   FROM public.bookings
  WHERE ((bookings.requester_id = auth.uid()) OR (bookings.traveler_id = auth.uid()))))));


--
-- TOC entry 5601 (class 3256 OID 52266)
-- Name: profiles Users can insert their own profile.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK ((auth.uid() = id));


--
-- TOC entry 5551 (class 3256 OID 52282)
-- Name: notification_tokens Users can manage their own tokens.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage their own tokens." ON public.notification_tokens USING (((auth.uid() = user_id) OR public.is_admin()));


--
-- TOC entry 5584 (class 3256 OID 27770)
-- Name: messages Users can update messages for their bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update messages for their bookings" ON public.messages FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.bookings
  WHERE ((bookings.id = messages.booking_id) AND ((bookings.requester_id = auth.uid()) OR (bookings.traveler_id = auth.uid()))))));


--
-- TOC entry 5582 (class 3256 OID 52337)
-- Name: profiles Users can update own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (((auth.uid() = id) OR (public.is_admin() AND (NOT is_admin))));


--
-- TOC entry 5609 (class 3256 OID 52276)
-- Name: blocks Users can view blocks they are part of.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view blocks they are part of." ON public.blocks FOR SELECT USING (((auth.uid() = blocker_id) OR (auth.uid() = blocked_id) OR public.is_admin()));


--
-- TOC entry 5564 (class 3256 OID 52288)
-- Name: reports Users can view their own reports.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own reports." ON public.reports FOR SELECT USING (((auth.uid() = reporter_id) OR public.is_admin()));


--
-- TOC entry 5550 (class 3256 OID 93075)
-- Name: notifications Users delete own notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users delete own notifications" ON public.notifications FOR DELETE USING (((auth.uid() = user_id) OR public.is_admin()));


--
-- TOC entry 5566 (class 3256 OID 52291)
-- Name: route_alerts Users manage their route alerts.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users manage their route alerts." ON public.route_alerts USING (((auth.uid() = user_id) OR public.is_admin()));


--
-- TOC entry 5591 (class 3256 OID 52302)
-- Name: support_messages Users read their ticket messages.; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users read their ticket messages." ON public.support_messages FOR SELECT USING (((ticket_id IN ( SELECT support_tickets.id
   FROM public.support_tickets
  WHERE (support_tickets.user_id = auth.uid()))) OR public.is_admin()));


--
-- TOC entry 5549 (class 3256 OID 93074)
-- Name: notifications Users read/delete own notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users read/delete own notifications" ON public.notifications FOR SELECT USING (((auth.uid() = user_id) OR public.is_admin()));


--
-- TOC entry 5555 (class 3256 OID 93077)
-- Name: notifications Users update own notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users update own notifications" ON public.notifications FOR UPDATE USING (((auth.uid() = user_id) OR public.is_admin())) WITH CHECK (((auth.uid() = user_id) OR public.is_admin()));


--
-- TOC entry 5520 (class 0 OID 39373)
-- Dependencies: 422
-- Name: admin_audit_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5536 (class 0 OID 93366)
-- Dependencies: 451
-- Name: admin_login_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_login_events ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5580 (class 3256 OID 93402)
-- Name: admin_login_events admin_login_events_insert_admins; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY admin_login_events_insert_admins ON public.admin_login_events FOR INSERT WITH CHECK ((public.is_admin() AND (admin_id = auth.uid())));


--
-- TOC entry 5680 (class 0 OID 0)
-- Dependencies: 5580
-- Name: POLICY admin_login_events_insert_admins ON admin_login_events; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON POLICY admin_login_events_insert_admins ON public.admin_login_events IS 'Allows admins to insert their own login and logout events';


--
-- TOC entry 5576 (class 3256 OID 93381)
-- Name: admin_login_events admin_login_events_select_admins; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY admin_login_events_select_admins ON public.admin_login_events FOR SELECT USING (public.is_admin());


--
-- TOC entry 5532 (class 0 OID 52607)
-- Dependencies: 436
-- Name: admin_preferences; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_preferences ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5514 (class 0 OID 23113)
-- Dependencies: 410
-- Name: ads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ads ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5518 (class 0 OID 35838)
-- Dependencies: 420
-- Name: app_config; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5524 (class 0 OID 49962)
-- Dependencies: 427
-- Name: app_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5600 (class 3256 OID 92958)
-- Name: app_settings app_settings admin write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "app_settings admin write" ON public.app_settings FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.is_admin = true))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.is_admin = true)))));


--
-- TOC entry 5525 (class 0 OID 52430)
-- Dependencies: 428
-- Name: audit_logs_v2; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audit_logs_v2 ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5531 (class 0 OID 52584)
-- Dependencies: 435
-- Name: blacklist; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.blacklist ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5511 (class 0 OID 20254)
-- Dependencies: 407
-- Name: blocks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5508 (class 0 OID 20188)
-- Dependencies: 404
-- Name: bookings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5594 (class 3256 OID 39328)
-- Name: bookings bookings_delete_pending; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bookings_delete_pending ON public.bookings FOR DELETE TO authenticated USING (((status = 'pending'::text) AND ((traveler_id = ( SELECT auth.uid() AS uid)) OR (requester_id = ( SELECT auth.uid() AS uid)))));


--
-- TOC entry 5620 (class 3256 OID 55378)
-- Name: bookings bookings_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bookings_insert ON public.bookings FOR INSERT WITH CHECK (((requester_id = auth.uid()) AND (trip_id IS NOT NULL)));


--
-- TOC entry 5619 (class 3256 OID 55377)
-- Name: bookings bookings_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bookings_select ON public.bookings FOR SELECT USING (((requester_id = auth.uid()) OR (traveler_id = auth.uid()) OR public.is_admin()));


--
-- TOC entry 5593 (class 3256 OID 39326)
-- Name: bookings bookings_select_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bookings_select_admin ON public.bookings FOR SELECT TO authenticated USING (( SELECT public.is_admin() AS is_admin));


--
-- TOC entry 5547 (class 3256 OID 93073)
-- Name: bookings bookings_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bookings_update ON public.bookings FOR UPDATE USING (((requester_id = auth.uid()) OR (traveler_id = auth.uid()) OR public.has_role('support_agent'::public.admin_role))) WITH CHECK (((requester_id = auth.uid()) OR (traveler_id = auth.uid()) OR public.has_role('support_agent'::public.admin_role)));


--
-- TOC entry 5537 (class 0 OID 94301)
-- Dependencies: 453
-- Name: delivery_codes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.delivery_codes ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5585 (class 3256 OID 94326)
-- Name: delivery_codes delivery_codes_select_sender; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY delivery_codes_select_sender ON public.delivery_codes FOR SELECT TO authenticated USING ((((booking_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.bookings b
  WHERE ((b.id = delivery_codes.booking_id) AND (b.requester_id = auth.uid()))))) OR public.is_admin()));


--
-- TOC entry 5534 (class 0 OID 52642)
-- Dependencies: 438
-- Name: export_jobs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.export_jobs ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5512 (class 0 OID 22854)
-- Dependencies: 408
-- Name: locations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5509 (class 0 OID 20213)
-- Dependencies: 405
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5596 (class 3256 OID 39648)
-- Name: messages messages_insert_not_blocked; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY messages_insert_not_blocked ON public.messages FOR INSERT WITH CHECK (((sender_id = auth.uid()) AND (NOT public.is_user_blocked())));


--
-- TOC entry 5515 (class 0 OID 27720)
-- Dependencies: 411
-- Name: notification_tokens; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notification_tokens ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5516 (class 0 OID 27737)
-- Dependencies: 412
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5626 (class 3256 OID 55388)
-- Name: messages messages_select_participant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY messages_select_participant ON public.messages FOR SELECT USING ((((booking_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.bookings b
  WHERE ((b.id = messages.booking_id) AND ((b.requester_id = auth.uid()) OR (b.traveler_id = auth.uid())))))) OR public.is_admin()));


--
-- TOC entry 5504 (class 0 OID 18839)
-- Dependencies: 400
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5507 (class 0 OID 19029)
-- Dependencies: 403
-- Name: ratings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5598 (class 3256 OID 39394)
-- Name: ratings ratings_delete_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY ratings_delete_own ON public.ratings FOR DELETE TO authenticated USING ((rater_id = ( SELECT auth.uid() AS uid)));


--
-- TOC entry 5599 (class 3256 OID 39649)
-- Name: ratings ratings_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY ratings_insert_own ON public.ratings FOR INSERT WITH CHECK (((rater_id = auth.uid()) AND (NOT public.is_user_blocked())));


--
-- TOC entry 5597 (class 3256 OID 39393)
-- Name: ratings ratings_update_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY ratings_update_own ON public.ratings FOR UPDATE TO authenticated USING ((rater_id = ( SELECT auth.uid() AS uid)));


--
-- TOC entry 5510 (class 0 OID 20235)
-- Dependencies: 406
-- Name: reports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5595 (class 3256 OID 39392)
-- Name: reports reports_select_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reports_select_admin ON public.reports FOR SELECT TO authenticated USING (( SELECT public.is_moderator_or_above() AS is_moderator_or_above));


--
-- TOC entry 5528 (class 0 OID 52524)
-- Dependencies: 432
-- Name: risk_score_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.risk_score_history ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5517 (class 0 OID 31328)
-- Dependencies: 419
-- Name: route_alerts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.route_alerts ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5533 (class 0 OID 52626)
-- Dependencies: 437
-- Name: saved_filters; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.saved_filters ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5521 (class 0 OID 39463)
-- Dependencies: 423
-- Name: scheduled_notifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.scheduled_notifications ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5523 (class 0 OID 39607)
-- Dependencies: 425
-- Name: support_messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5603 (class 3256 OID 39638)
-- Name: support_messages support_messages_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY support_messages_insert ON public.support_messages FOR INSERT WITH CHECK (((sender_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.support_tickets t
  WHERE ((t.id = support_messages.ticket_id) AND ((t.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.profiles
          WHERE ((profiles.id = auth.uid()) AND (profiles.is_admin = true))))))))));


--
-- TOC entry 5605 (class 3256 OID 39639)
-- Name: support_messages support_messages_update_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY support_messages_update_admin ON public.support_messages FOR UPDATE USING (((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.is_admin = true)))) OR (EXISTS ( SELECT 1
   FROM public.support_tickets t
  WHERE ((t.id = support_messages.ticket_id) AND (t.user_id = auth.uid()))))));


--
-- TOC entry 5522 (class 0 OID 39585)
-- Dependencies: 424
-- Name: support_tickets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5572 (class 3256 OID 93365)
-- Name: support_tickets support_tickets_delete_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY support_tickets_delete_admin ON public.support_tickets FOR DELETE USING (public.is_admin());


--
-- TOC entry 5570 (class 3256 OID 93363)
-- Name: support_tickets support_tickets_insert_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY support_tickets_insert_owner_admin ON public.support_tickets FOR INSERT WITH CHECK (((auth.uid() = user_id) OR public.is_admin()));


--
-- TOC entry 5569 (class 3256 OID 93362)
-- Name: support_tickets support_tickets_select_owner_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY support_tickets_select_owner_admin ON public.support_tickets FOR SELECT USING (((auth.uid() = user_id) OR public.is_admin()));


--
-- TOC entry 5571 (class 3256 OID 93364)
-- Name: support_tickets support_tickets_update_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY support_tickets_update_admin ON public.support_tickets FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 5513 (class 0 OID 23066)
-- Dependencies: 409
-- Name: trips; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5581 (class 3256 OID 28979)
-- Name: trips trips_delete_traveler; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY trips_delete_traveler ON public.trips FOR DELETE USING ((auth.uid() = traveler_id));


--
-- TOC entry 5577 (class 3256 OID 49832)
-- Name: trips trips_insert_allowed_for_approved_travelers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY trips_insert_allowed_for_approved_travelers ON public.trips FOR INSERT TO authenticated WITH CHECK (((traveler_id = auth.uid()) AND (( SELECT profiles.traveler_status
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'approved'::text)));


--
-- TOC entry 5592 (class 3256 OID 39325)
-- Name: trips trips_update_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY trips_update_admin ON public.trips FOR UPDATE TO authenticated USING (( SELECT public.is_admin() AS is_admin));


--
-- TOC entry 5578 (class 3256 OID 49833)
-- Name: trips trips_update_allowed_for_approved_travelers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY trips_update_allowed_for_approved_travelers ON public.trips FOR UPDATE TO authenticated USING ((traveler_id = auth.uid())) WITH CHECK (((traveler_id = auth.uid()) AND (( SELECT profiles.traveler_status
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'approved'::text)));


--
-- TOC entry 5526 (class 0 OID 52477)
-- Dependencies: 429
-- Name: user_restrictions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_restrictions ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5527 (class 0 OID 52508)
-- Dependencies: 431
-- Name: user_risk_scores; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_risk_scores ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5506 (class 0 OID 18999)
-- Dependencies: 402
-- Name: vehicles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5590 (class 3256 OID 94387)
-- Name: vehicles vehicles_select_own_or_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY vehicles_select_own_or_admin ON public.vehicles FOR SELECT USING (((auth.uid() = owner_id) OR public.is_admin()));


--
-- TOC entry 5529 (class 0 OID 52546)
-- Dependencies: 433
-- Name: verification_documents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.verification_documents ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5530 (class 0 OID 52569)
-- Dependencies: 434
-- Name: verification_workflow; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.verification_workflow ENABLE ROW LEVEL SECURITY;

-- Completed on 2026-06-18 22:14:10

--
-- PostgreSQL database dump complete
--

