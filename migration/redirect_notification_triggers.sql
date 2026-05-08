-- =====================================================================
-- Migration Loop 5: Redirect notification triggers from Supabase → VPS
-- =====================================================================
-- Run on the VPS Postgres DB:
--   psql "$DATABASE_URL" -f migration/redirect_notification_triggers.sql
--
-- Why: The 6 notify_* trigger functions reference vault.decrypted_secrets
-- (Supabase-only) — they fail silently in production on the local VPS DB.
-- This migration:
--   1. Repoints notify_booking_completed at https://triptastic.com.bd/api/booking-notifications
--      (unauthenticated public route; matches existing VPS endpoint).
--   2. Replaces the other 5 functions with safe no-ops until an internal
--      auth-bearing endpoint is added (planned in a later loop).
-- Idempotent: safe to re-run.
-- =====================================================================

-- Ensure pg_net is available
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ---------------------------------------------------------------------
-- 1) notify_booking_completed → VPS /api/booking-notifications
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
-- 2-6) Neutralize the 5 trigger functions that called /functions/v1/send-notification.
--      These have been failing silently since the VPS migration; turning
--      them into safe no-ops avoids surprise behaviour. A future loop will
--      add an internal /api/internal/send-notification endpoint (HMAC-secured)
--      and restore the bodies.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_booking_created() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
    AS $$ BEGIN RETURN NEW; END; $$;

CREATE OR REPLACE FUNCTION public.notify_booking_status_updated() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
    AS $$ BEGIN RETURN NEW; END; $$;

CREATE OR REPLACE FUNCTION public.notify_payment_completed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
    AS $$ BEGIN RETURN NEW; END; $$;

CREATE OR REPLACE FUNCTION public.notify_commission_payment() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
    AS $$ BEGIN RETURN NEW; END; $$;

CREATE OR REPLACE FUNCTION public.notify_supplier_payment() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
    AS $$ BEGIN RETURN NEW; END; $$;

-- =====================================================================
-- Verify
--   SELECT prosrc FROM pg_proc WHERE proname='notify_booking_completed';
-- Should contain 'triptastic.com.bd/api/booking-notifications'.
-- =====================================================================
