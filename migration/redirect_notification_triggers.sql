-- =====================================================================
-- Migration Loop 5+6: Redirect notification triggers to VPS
-- =====================================================================
-- Run on the VPS Postgres DB:
--   psql "$DATABASE_URL" -f migration/redirect_notification_triggers.sql
--
-- PREREQUISITE (Loop 6): Set the internal trigger secret as a DB-level GUC
-- so trigger functions can read it without leaking via pg_proc:
--
--   ALTER DATABASE triptastic SET app.internal_trigger_secret =
--     '<same value as INTERNAL_TRIGGER_SECRET in server/.env>';
--
-- After ALTER DATABASE, reconnect (close & reopen psql / restart pg pool)
-- for the new GUC to take effect on existing sessions.
--
-- Why: The original 6 notify_* functions referenced vault.decrypted_secrets
-- (Supabase-only). They failed silently in production. This migration:
--   1. Repoints notify_booking_completed → /api/booking-notifications
--      (unauthenticated public route).
--   2. Repoints the other 5 → /api/internal/send-notification
--      (HMAC-style shared-secret header).
-- Idempotent: safe to re-run.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS pg_net;

-- ---------------------------------------------------------------------
-- 1) notify_booking_completed → /api/booking-notifications
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_booking_completed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status <> 'completed') THEN
    BEGIN
      PERFORM net.http_post(
        url := 'https://triptastic.com.bd/api/booking-notifications',
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := jsonb_build_object('booking_id', NEW.id)
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_booking_completed failed: %', SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------
-- 2) notify_booking_created → internal /api/internal/send-notification
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_booking_created() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    BEGIN
      PERFORM net.http_post(
        url := 'https://triptastic.com.bd/api/internal/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'X-Internal-Secret', current_setting('app.internal_trigger_secret', true)
        ),
        body := jsonb_build_object(
          'type', 'booking_created',
          'channels', jsonb_build_array('email', 'sms'),
          'user_id', COALESCE(NEW.user_id, '00000000-0000-0000-0000-000000000000'),
          'booking_id', NEW.id
        )
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_booking_created failed: %', SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------
-- 3) notify_booking_status_updated → internal endpoint
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_booking_status_updated() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status AND NEW.status <> 'completed' THEN
    BEGIN
      PERFORM net.http_post(
        url := 'https://triptastic.com.bd/api/internal/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'X-Internal-Secret', current_setting('app.internal_trigger_secret', true)
        ),
        body := jsonb_build_object(
          'type', 'booking_status_updated',
          'channels', jsonb_build_array('email', 'sms'),
          'user_id', COALESCE(NEW.user_id, '00000000-0000-0000-0000-000000000000'),
          'booking_id', NEW.id,
          'extra', jsonb_build_object('new_status', NEW.status)
        )
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_booking_status_updated failed: %', SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------
-- 4) notify_payment_completed → internal endpoint
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_payment_completed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE v_user_id UUID;
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status <> 'completed') THEN
    SELECT COALESCE(NEW.user_id, (SELECT user_id FROM public.bookings WHERE id = NEW.booking_id))
      INTO v_user_id;
    BEGIN
      PERFORM net.http_post(
        url := 'https://triptastic.com.bd/api/internal/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'X-Internal-Secret', current_setting('app.internal_trigger_secret', true)
        ),
        body := jsonb_build_object(
          'type', 'payment_received',
          'channels', jsonb_build_array('email', 'sms'),
          'user_id', COALESCE(v_user_id, '00000000-0000-0000-0000-000000000000'),
          'booking_id', NEW.booking_id,
          'payment_id', NEW.id,
          'extra', jsonb_build_object(
            'amount', NEW.amount,
            'installment_number', NEW.installment_number
          )
        )
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_payment_completed failed: %', SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------
-- 5) notify_commission_payment → internal endpoint
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_commission_payment() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_moallem_name TEXT;
  v_booking_user_id UUID;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT name INTO v_moallem_name FROM public.moallems WHERE id = NEW.moallem_id;
    IF NEW.booking_id IS NOT NULL THEN
      SELECT user_id INTO v_booking_user_id FROM public.bookings WHERE id = NEW.booking_id;
    END IF;
    BEGIN
      PERFORM net.http_post(
        url := 'https://triptastic.com.bd/api/internal/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'X-Internal-Secret', current_setting('app.internal_trigger_secret', true)
        ),
        body := jsonb_build_object(
          'type', 'commission_paid',
          'channels', jsonb_build_array('email'),
          'user_id', COALESCE(NEW.recorded_by, v_booking_user_id, '00000000-0000-0000-0000-000000000000'),
          'booking_id', NEW.booking_id,
          'extra', jsonb_build_object(
            'amount', NEW.amount,
            'moallem_name', COALESCE(v_moallem_name, 'Unknown')
          )
        )
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_commission_payment failed: %', SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------
-- 6) notify_supplier_payment → internal endpoint
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_supplier_payment() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_supplier_name TEXT;
  v_booking_user_id UUID;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT name INTO v_supplier_name FROM public.supplier_agents WHERE id = NEW.supplier_agent_id;
    IF NEW.booking_id IS NOT NULL THEN
      SELECT user_id INTO v_booking_user_id FROM public.bookings WHERE id = NEW.booking_id;
    END IF;
    BEGIN
      PERFORM net.http_post(
        url := 'https://triptastic.com.bd/api/internal/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'X-Internal-Secret', current_setting('app.internal_trigger_secret', true)
        ),
        body := jsonb_build_object(
          'type', 'supplier_paid',
          'channels', jsonb_build_array('email'),
          'user_id', COALESCE(NEW.recorded_by, v_booking_user_id, '00000000-0000-0000-0000-000000000000'),
          'booking_id', NEW.booking_id,
          'extra', jsonb_build_object(
            'amount', NEW.amount,
            'supplier_name', COALESCE(v_supplier_name, 'Unknown')
          )
        )
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_supplier_payment failed: %', SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;

-- =====================================================================
-- Verify
--   SELECT proname FROM pg_proc
--    WHERE proname LIKE 'notify_%' AND prosrc LIKE '%triptastic.com.bd%';
-- Should return all 6 functions.
-- =====================================================================
