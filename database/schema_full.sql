--
-- PostgreSQL database dump
--

\restrict 5G7GNXracf6d8n9Twva9IYLtK1zOF4gVUR6IxlhPr5LlmK0e56Wyhfchz45aWAS

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET escape_string_warning = off;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: app_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.app_role AS ENUM (
    'admin',
    'user',
    'manager',
    'staff',
    'viewer',
    'accountant',
    'booking',
    'cms'
);


--
-- Name: auto_assign_wallet(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auto_assign_wallet() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_wallet_id UUID;
  v_method TEXT;
BEGIN
  -- Default payment_method to 'cash' if not set
  IF NEW.payment_method IS NULL OR NEW.payment_method = '' THEN
    NEW.payment_method := 'cash';
  END IF;

  v_method := NEW.payment_method;

  -- Only assign if wallet_account_id is not already set
  IF NEW.wallet_account_id IS NULL THEN
    SELECT id INTO v_wallet_id FROM public.accounts
    WHERE type = 'asset' AND (
      (v_method = 'cash' AND name = 'Cash') OR
      (v_method = 'manual' AND name = 'Cash') OR
      (v_method = 'bank' AND name = 'Bank') OR
      (v_method = 'bank_transfer' AND name = 'Bank') OR
      (v_method = 'bkash' AND name = 'bKash') OR
      (v_method = 'nagad' AND name = 'Nagad') OR
      (v_method = 'online' AND name = 'Bank')
    ) LIMIT 1;

    IF v_wallet_id IS NOT NULL THEN
      NEW.wallet_account_id := v_wallet_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: calc_ticket_booking_fields(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calc_ticket_booking_fields() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.profit := COALESCE(NEW.customer_billing_amount, 0) - COALESCE(NEW.our_cost, 0);
  NEW.customer_due := GREATEST(0, COALESCE(NEW.customer_billing_amount, 0) - COALESCE(NEW.received_amount, 0));
  IF NEW.received_amount <= 0 THEN
    NEW.payment_status := 'due';
  ELSIF NEW.received_amount >= NEW.customer_billing_amount THEN
    NEW.payment_status := 'paid';
  ELSE
    NEW.payment_status := 'partial';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;


--
-- Name: calc_ticket_refund_fields(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calc_ticket_refund_fields() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.profit := COALESCE(NEW.customer_refund_charge, 0) - COALESCE(NEW.our_refund_charge, 0);
  NEW.due := GREATEST(0, COALESCE(NEW.customer_refund_charge, 0) - COALESCE(NEW.bill_received, 0));
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;


--
-- Name: calc_visa_application_fields(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calc_visa_application_fields() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.profit := COALESCE(NEW.billing_amount, 0) - COALESCE(NEW.our_cost, 0);
  NEW.customer_due := GREATEST(0, COALESCE(NEW.billing_amount, 0) - COALESCE(NEW.received_amount, 0));
  IF NEW.received_amount <= 0 THEN
    NEW.payment_status := 'due';
  ELSIF NEW.received_amount >= NEW.billing_amount THEN
    NEW.payment_status := 'paid';
  ELSE
    NEW.payment_status := 'partial';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;


--
-- Name: calculate_booking_profit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_booking_profit() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  -- For family bookings, total_amount is set from members sum, don't overwrite
  IF COALESCE(NEW.booking_type, 'individual') = 'individual' THEN
    NEW.total_amount := COALESCE(NEW.selling_price_per_person, 0) * COALESCE(NEW.num_travelers, 1);
  END IF;
  
  NEW.total_cost := COALESCE(NEW.cost_price_per_person, 0) * COALESCE(NEW.num_travelers, 1);
  NEW.total_commission := COALESCE(NEW.commission_per_person, 0) * COALESCE(NEW.num_travelers, 1);
  NEW.commission_due := GREATEST(0, COALESCE(NEW.total_commission, 0) - COALESCE(NEW.commission_paid, 0));
  NEW.profit_amount := NEW.total_amount - COALESCE(NEW.total_cost, 0) - COALESCE(NEW.total_commission, 0) - COALESCE(NEW.extra_expense, 0);
  NEW.due_amount := GREATEST(0, NEW.total_amount - COALESCE(NEW.paid_amount, 0));
  NEW.supplier_due := GREATEST(0, COALESCE(NEW.total_cost, 0) - COALESCE(NEW.paid_to_supplier, 0));
  IF NEW.moallem_id IS NOT NULL THEN
    NEW.moallem_due := GREATEST(0, NEW.total_amount - COALESCE(NEW.paid_by_moallem, 0));
  ELSE
    NEW.moallem_due := 0;
    NEW.commission_per_person := 0;
    NEW.total_commission := 0;
    NEW.commission_paid := 0;
    NEW.commission_due := 0;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: check_package_expiry(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_package_expiry() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.expiry_date IS NOT NULL AND NEW.expiry_date < CURRENT_DATE THEN
    NEW.status := 'inactive';
    NEW.is_active := false;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: deactivate_expired_packages(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deactivate_expired_packages() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  UPDATE public.packages
  SET status = 'inactive', is_active = false
  WHERE expiry_date IS NOT NULL
    AND expiry_date < CURRENT_DATE
    AND status = 'active';
END;
$$;


--
-- Name: gen_refund_invoice_no(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gen_refund_invoice_no() RETURNS text
    LANGUAGE sql
    AS $$
  SELECT 'RFN' || to_char(CURRENT_DATE, 'YYYY') || lpad(nextval('public.refund_invoice_seq')::text, 5, '0')
$$;


--
-- Name: gen_settlement_no(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gen_settlement_no() RETURNS text
    LANGUAGE sql
    AS $$
  SELECT 'STM' || to_char(CURRENT_DATE, 'YYYY') || lpad(nextval('public.settlement_no_seq')::text, 7, '0')
$$;


--
-- Name: gen_ticket_invoice_no(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gen_ticket_invoice_no() RETURNS text
    LANGUAGE sql
    AS $$
  SELECT 'TKT' || to_char(CURRENT_DATE, 'YYYY') || lpad(nextval('public.ticket_invoice_seq')::text, 5, '0')
$$;


--
-- Name: gen_visa_invoice_no(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gen_visa_invoice_no() RETURNS text
    LANGUAGE sql
    AS $$
  SELECT 'VS' || to_char(CURRENT_DATE, 'YYYY') || lpad(nextval('public.visa_invoice_seq')::text, 5, '0')
$$;


--
-- Name: generate_installment_schedule(uuid, numeric, integer, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_installment_schedule(p_booking_id uuid, p_total_amount numeric, p_num_installments integer, p_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  installment_amount NUMERIC;
  i INTEGER;
BEGIN
  installment_amount := ROUND(p_total_amount / p_num_installments, 2);
  FOR i IN 1..p_num_installments LOOP
    INSERT INTO public.payments (booking_id, user_id, amount, installment_number, due_date, status)
    VALUES (
      p_booking_id,
      p_user_id,
      CASE WHEN i = p_num_installments THEN p_total_amount - (installment_amount * (p_num_installments - 1)) ELSE installment_amount END,
      i,
      CURRENT_DATE + (i * 30),
      'pending'
    );
  END LOOP;
END;
$$;


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.profiles (user_id, full_name, phone)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.raw_user_meta_data ->> 'phone'
  );
  RETURN NEW;
END;
$$;


--
-- Name: has_role(uuid, public.app_role); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.has_role(_user_id uuid, _role public.app_role) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;


--
-- Name: notify_booking_completed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_booking_completed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status <> 'completed') THEN
    BEGIN
      PERFORM net.http_post(
        url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_URL') || '/functions/v1/booking-notifications',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_SERVICE_ROLE_KEY')
        ),
        body := jsonb_build_object('booking_id', NEW.id)
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_booking_completed failed: %', SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: notify_booking_created(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_booking_created() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    BEGIN
      PERFORM net.http_post(
        url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_URL') || '/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_SERVICE_ROLE_KEY')
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


--
-- Name: notify_booking_status_updated(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_booking_status_updated() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status AND NEW.status <> 'completed' THEN
    BEGIN
      PERFORM net.http_post(
        url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_URL') || '/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_SERVICE_ROLE_KEY')
        ),
        body := jsonb_build_object(
          'type', 'booking_status_updated',
          'channels', jsonb_build_array('email', 'sms'),
          'user_id', COALESCE(NEW.user_id, '00000000-0000-0000-0000-000000000000'),
          'booking_id', NEW.id,
          'new_status', NEW.status
        )
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_booking_status_updated failed: %', SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: notify_commission_payment(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_commission_payment() RETURNS trigger
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
        url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_URL') || '/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_SERVICE_ROLE_KEY')
        ),
        body := jsonb_build_object(
          'type', 'commission_paid',
          'channels', jsonb_build_array('email'),
          'user_id', COALESCE(NEW.recorded_by, v_booking_user_id, '00000000-0000-0000-0000-000000000000'),
          'booking_id', NEW.booking_id,
          'amount', NEW.amount,
          'moallem_name', COALESCE(v_moallem_name, 'Unknown')
        )
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_commission_payment failed: %', SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: notify_payment_completed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_payment_completed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status <> 'completed') THEN
    BEGIN
      PERFORM net.http_post(
        url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_URL') || '/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_SERVICE_ROLE_KEY')
        ),
        body := jsonb_build_object(
          'type', 'payment_received',
          'channels', jsonb_build_array('email', 'sms'),
          'user_id', COALESCE(NEW.user_id, (SELECT user_id FROM public.bookings WHERE id = NEW.booking_id)),
          'booking_id', NEW.booking_id,
          'payment_id', NEW.id,
          'amount', NEW.amount,
          'installment_number', NEW.installment_number
        )
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_payment_completed failed: %', SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: notify_supplier_payment(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_supplier_payment() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_supplier_name TEXT;
  v_booking_user_id UUID;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT agent_name INTO v_supplier_name FROM public.supplier_agents WHERE id = NEW.supplier_agent_id;
    
    IF NEW.booking_id IS NOT NULL THEN
      SELECT user_id INTO v_booking_user_id FROM public.bookings WHERE id = NEW.booking_id;
    END IF;

    BEGIN
      PERFORM net.http_post(
        url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_URL') || '/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'SUPABASE_SERVICE_ROLE_KEY')
        ),
        body := jsonb_build_object(
          'type', 'supplier_payment_recorded',
          'channels', jsonb_build_array('email'),
          'user_id', COALESCE(NEW.recorded_by, v_booking_user_id, '00000000-0000-0000-0000-000000000000'),
          'booking_id', NEW.booking_id,
          'amount', NEW.amount,
          'supplier_name', COALESCE(v_supplier_name, 'Unknown')
        )
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_supplier_payment failed: %', SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: on_commission_payment_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.on_commission_payment_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_moallem_name TEXT;
  v_wallet_balance NUMERIC;
  v_total_income NUMERIC;
  v_total_expense NUMERIC;
  v_expense_total NUMERIC;
BEGIN
  IF TG_OP = 'INSERT' AND NEW.wallet_account_id IS NOT NULL THEN
    SELECT balance INTO v_wallet_balance FROM public.accounts WHERE id = NEW.wallet_account_id;
    IF v_wallet_balance < NEW.amount THEN
      RAISE EXCEPTION 'Insufficient wallet balance. Available: %, Required: %', v_wallet_balance, NEW.amount;
    END IF;
    UPDATE public.accounts SET balance = balance - NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = balance + OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
    END IF;
    IF NEW.wallet_account_id IS NOT NULL THEN
      SELECT balance INTO v_wallet_balance FROM public.accounts WHERE id = NEW.wallet_account_id;
      IF v_wallet_balance < NEW.amount THEN
        RAISE EXCEPTION 'Insufficient wallet balance. Available: %, Required: %', v_wallet_balance, NEW.amount;
      END IF;
      UPDATE public.accounts SET balance = balance - NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
    END IF;
  ELSIF TG_OP = 'DELETE' AND OLD.wallet_account_id IS NOT NULL THEN
    UPDATE public.accounts SET balance = balance + OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
  END IF;

  SELECT name INTO v_moallem_name FROM public.moallems
  WHERE id = COALESCE(NEW.moallem_id, OLD.moallem_id);

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.transactions (type, category, amount, debit, credit, source_type, source_id, user_id, date, note, payment_method, reference)
    VALUES ('expense', 'commission_payment', NEW.amount, 0, NEW.amount, 'commission', NEW.moallem_id,
      COALESCE(NEW.recorded_by, '00000000-0000-0000-0000-000000000000'::uuid),
      NEW.date, 'Commission payment to ' || COALESCE(v_moallem_name, 'Unknown'),
      NEW.payment_method, NEW.id::text);
  ELSIF TG_OP = 'UPDATE' THEN
    DELETE FROM public.transactions WHERE reference = OLD.id::text AND type = 'expense' AND category = 'commission_payment';
    INSERT INTO public.transactions (type, category, amount, debit, credit, source_type, source_id, user_id, date, note, payment_method, reference)
    VALUES ('expense', 'commission_payment', NEW.amount, 0, NEW.amount, 'commission', NEW.moallem_id,
      COALESCE(NEW.recorded_by, '00000000-0000-0000-0000-000000000000'::uuid),
      NEW.date, 'Commission payment to ' || COALESCE(v_moallem_name, 'Unknown'),
      NEW.payment_method, NEW.id::text);
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.transactions WHERE reference = OLD.id::text AND type = 'expense' AND category = 'commission_payment';
  END IF;

  SELECT COALESCE(SUM(debit), 0), COALESCE(SUM(credit), 0)
  INTO v_total_income, v_total_expense FROM public.transactions;

  SELECT COALESCE(SUM(amount), 0) INTO v_expense_total FROM public.expenses;
  v_total_expense := v_total_expense + v_expense_total;

  IF EXISTS (SELECT 1 FROM public.financial_summary LIMIT 1) THEN
    UPDATE public.financial_summary
    SET total_income = v_total_income, total_expense = v_total_expense,
        net_profit = v_total_income - v_total_expense, updated_at = now()
    WHERE id IS NOT NULL;
  ELSE
    INSERT INTO public.financial_summary (total_income, total_expense, net_profit)
    VALUES (v_total_income, v_total_expense, v_total_income - v_total_expense);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: on_expense_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.on_expense_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_total_income NUMERIC;
  v_total_expense NUMERIC;
  v_expense_total NUMERIC;
  v_wallet_balance NUMERIC;
BEGIN
  IF TG_OP = 'INSERT' AND NEW.wallet_account_id IS NOT NULL THEN
    SELECT balance INTO v_wallet_balance FROM public.accounts WHERE id = NEW.wallet_account_id;
    IF v_wallet_balance < NEW.amount THEN
      RAISE EXCEPTION 'Insufficient wallet balance. Available: %, Required: %', v_wallet_balance, NEW.amount;
    END IF;
    UPDATE public.accounts SET balance = balance - NEW.amount, updated_at = now()
    WHERE id = NEW.wallet_account_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = balance + OLD.amount, updated_at = now()
      WHERE id = OLD.wallet_account_id;
    END IF;
    IF NEW.wallet_account_id IS NOT NULL THEN
      SELECT balance INTO v_wallet_balance FROM public.accounts WHERE id = NEW.wallet_account_id;
      IF v_wallet_balance < NEW.amount THEN
        RAISE EXCEPTION 'Insufficient wallet balance. Available: %, Required: %', v_wallet_balance, NEW.amount;
      END IF;
      UPDATE public.accounts SET balance = balance - NEW.amount, updated_at = now()
      WHERE id = NEW.wallet_account_id;
    END IF;
  ELSIF TG_OP = 'DELETE' AND OLD.wallet_account_id IS NOT NULL THEN
    UPDATE public.accounts SET balance = balance + OLD.amount, updated_at = now()
    WHERE id = OLD.wallet_account_id;
  END IF;

  SELECT COALESCE(SUM(amount), 0) INTO v_expense_total FROM public.expenses;

  UPDATE public.accounts SET balance = v_expense_total, updated_at = now()
  WHERE type = 'expense' AND name = 'Operating Expenses';
  IF NOT FOUND THEN
    INSERT INTO public.accounts (name, type, balance) VALUES ('Operating Expenses', 'expense', v_expense_total);
  END IF;

  SELECT COALESCE(SUM(debit), 0), COALESCE(SUM(credit), 0)
  INTO v_total_income, v_total_expense
  FROM public.transactions;

  v_total_expense := v_total_expense + v_expense_total;

  IF EXISTS (SELECT 1 FROM public.financial_summary LIMIT 1) THEN
    UPDATE public.financial_summary
    SET total_expense = v_total_expense, total_income = v_total_income,
        net_profit = v_total_income - v_total_expense, updated_at = now()
    WHERE id IS NOT NULL;
  ELSE
    INSERT INTO public.financial_summary (total_income, total_expense, net_profit)
    VALUES (v_total_income, v_total_expense, v_total_income - v_total_expense);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: on_moallem_payment_income(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.on_moallem_payment_income() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_moallem_name TEXT;
  v_total_income NUMERIC;
  v_total_expense NUMERIC;
  v_expense_total NUMERIC;
BEGIN
  SELECT name INTO v_moallem_name FROM public.moallems
  WHERE id = COALESCE(NEW.moallem_id, OLD.moallem_id);

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.transactions (type, category, amount, debit, credit, source_type, source_id, user_id, date, note, payment_method, reference, booking_id)
    VALUES ('income', 'moallem_payment', NEW.amount, NEW.amount, 0, 'moallem', NEW.moallem_id,
      COALESCE(NEW.recorded_by, '00000000-0000-0000-0000-000000000000'::uuid),
      NEW.date, 'Moallem payment from ' || COALESCE(v_moallem_name, 'Unknown'),
      NEW.payment_method, NEW.id::text, NEW.booking_id);

    UPDATE public.accounts SET balance = balance + NEW.amount, updated_at = now()
    WHERE type = 'income' AND name = 'Revenue';
    IF NOT FOUND THEN
      INSERT INTO public.accounts (name, type, balance) VALUES ('Revenue', 'income', NEW.amount);
    END IF;

  ELSIF TG_OP = 'UPDATE' THEN
    DELETE FROM public.transactions WHERE reference = OLD.id::text AND type = 'income' AND category = 'moallem_payment';
    UPDATE public.accounts SET balance = GREATEST(0, balance - OLD.amount), updated_at = now()
    WHERE type = 'income' AND name = 'Revenue';

    INSERT INTO public.transactions (type, category, amount, debit, credit, source_type, source_id, user_id, date, note, payment_method, reference, booking_id)
    VALUES ('income', 'moallem_payment', NEW.amount, NEW.amount, 0, 'moallem', NEW.moallem_id,
      COALESCE(NEW.recorded_by, '00000000-0000-0000-0000-000000000000'::uuid),
      NEW.date, 'Moallem payment from ' || COALESCE(v_moallem_name, 'Unknown'),
      NEW.payment_method, NEW.id::text, NEW.booking_id);
    UPDATE public.accounts SET balance = balance + NEW.amount, updated_at = now()
    WHERE type = 'income' AND name = 'Revenue';

  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.transactions WHERE reference = OLD.id::text AND type = 'income' AND category = 'moallem_payment';
    UPDATE public.accounts SET balance = GREATEST(0, balance - OLD.amount), updated_at = now()
    WHERE type = 'income' AND name = 'Revenue';
  END IF;

  SELECT COALESCE(SUM(debit), 0), COALESCE(SUM(credit), 0)
  INTO v_total_income, v_total_expense FROM public.transactions;

  SELECT COALESCE(SUM(amount), 0) INTO v_expense_total FROM public.expenses;
  v_total_expense := v_total_expense + v_expense_total;

  IF EXISTS (SELECT 1 FROM public.financial_summary LIMIT 1) THEN
    UPDATE public.financial_summary
    SET total_income = v_total_income, total_expense = v_total_expense,
        net_profit = v_total_income - v_total_expense, updated_at = now()
    WHERE id IS NOT NULL;
  ELSE
    INSERT INTO public.financial_summary (total_income, total_expense, net_profit)
    VALUES (v_total_income, v_total_expense, v_total_income - v_total_expense);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: on_moallem_payment_wallet(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.on_moallem_payment_wallet() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.wallet_account_id IS NOT NULL THEN
    -- Moallem payments are income: ADD to wallet
    UPDATE public.accounts SET balance = balance + NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Reverse old wallet change
    IF OLD.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = balance - OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
    END IF;
    -- Apply new wallet change (add income)
    IF NEW.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = balance + NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
    END IF;
  ELSIF TG_OP = 'DELETE' AND OLD.wallet_account_id IS NOT NULL THEN
    -- Reverse: subtract the income that was added
    UPDATE public.accounts SET balance = balance - OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: on_payment_completed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.on_payment_completed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_booking RECORD;
  v_total_income NUMERIC;
  v_total_expense NUMERIC;
  v_expense_total NUMERIC;
BEGIN
  -- === INSERT or UPDATE to 'completed' ===
  IF TG_OP IN ('INSERT', 'UPDATE') AND NEW.status = 'completed' 
     AND (TG_OP = 'INSERT' OR OLD.status IS NULL OR OLD.status <> 'completed') THEN

    SELECT id, tracking_id, package_id, user_id INTO v_booking
    FROM public.bookings WHERE id = NEW.booking_id;

    INSERT INTO public.transactions (
      type, category, amount, debit, credit, source_type, source_id,
      booking_id, user_id, date, note, payment_method, customer_id, reference
    ) VALUES (
      'income', 'payment', NEW.amount, NEW.amount, 0, 'customer', NEW.customer_id,
      NEW.booking_id,
      COALESCE(NEW.user_id, v_booking.user_id, '00000000-0000-0000-0000-000000000000'::uuid),
      CURRENT_DATE,
      'Payment #' || COALESCE(NEW.installment_number::text, 'N/A') || ' for ' || COALESCE(v_booking.tracking_id, ''),
      NEW.payment_method, NEW.customer_id, NEW.id::text
    );

    UPDATE public.accounts SET balance = balance + NEW.amount, updated_at = now()
    WHERE type = 'income' AND name = 'Revenue';
    IF NOT FOUND THEN
      INSERT INTO public.accounts (name, type, balance) VALUES ('Revenue', 'income', NEW.amount);
    END IF;

    IF NEW.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = balance + NEW.amount, updated_at = now()
      WHERE id = NEW.wallet_account_id;
    END IF;
  END IF;

  -- === UPDATE from 'completed' to something else ===
  IF TG_OP = 'UPDATE' AND OLD.status = 'completed' AND NEW.status <> 'completed' THEN
    DELETE FROM public.transactions WHERE reference = OLD.id::text AND type = 'income';

    UPDATE public.accounts SET balance = GREATEST(0, balance - OLD.amount), updated_at = now()
    WHERE type = 'income' AND name = 'Revenue';

    IF OLD.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = GREATEST(0, balance - OLD.amount), updated_at = now()
      WHERE id = OLD.wallet_account_id;
    END IF;
  END IF;

  -- === DELETE of a completed payment ===
  IF TG_OP = 'DELETE' AND OLD.status = 'completed' THEN
    DELETE FROM public.transactions WHERE reference = OLD.id::text AND type = 'income';

    UPDATE public.accounts SET balance = GREATEST(0, balance - OLD.amount), updated_at = now()
    WHERE type = 'income' AND name = 'Revenue';

    IF OLD.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = GREATEST(0, balance - OLD.amount), updated_at = now()
      WHERE id = OLD.wallet_account_id;
    END IF;
  END IF;

  -- === Recalculate financial_summary for all operations ===
  SELECT COALESCE(SUM(debit), 0), COALESCE(SUM(credit), 0)
  INTO v_total_income, v_total_expense FROM public.transactions;

  SELECT COALESCE(SUM(amount), 0) INTO v_expense_total FROM public.expenses;
  v_total_expense := v_total_expense + v_expense_total;

  IF EXISTS (SELECT 1 FROM public.financial_summary LIMIT 1) THEN
    UPDATE public.financial_summary
    SET total_income = v_total_income, total_expense = v_total_expense,
        net_profit = v_total_income - v_total_expense, updated_at = now()
    WHERE id IS NOT NULL;
  ELSE
    INSERT INTO public.financial_summary (total_income, total_expense, net_profit)
    VALUES (v_total_income, v_total_expense, v_total_income - v_total_expense);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: on_refund_processed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.on_refund_processed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_booking RECORD;
  v_total_income NUMERIC;
  v_total_expense NUMERIC;
  v_expense_total NUMERIC;
BEGIN
  IF NEW.status = 'processed' AND (OLD.status IS NULL OR OLD.status <> 'processed') THEN
    -- Deduct from wallet
    IF NEW.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = balance - NEW.refund_amount, updated_at = now() WHERE id = NEW.wallet_account_id;
    END IF;

    -- Update booking status to cancelled and adjust paid_amount
    SELECT * INTO v_booking FROM public.bookings WHERE id = NEW.booking_id;
    
    UPDATE public.bookings
    SET status = 'cancelled',
        paid_amount = GREATEST(0, paid_amount - NEW.refund_amount),
        due_amount = 0,
        updated_at = now()
    WHERE id = NEW.booking_id;

    -- Record in transactions as expense (refund outflow)
    INSERT INTO public.transactions (type, category, amount, debit, credit, source_type, source_id, user_id, date, note, payment_method, reference, booking_id)
    VALUES ('expense', 'refund', NEW.refund_amount, 0, NEW.refund_amount, 'refund', NEW.id,
      COALESCE(NEW.processed_by, '00000000-0000-0000-0000-000000000000'::uuid),
      CURRENT_DATE, 'Refund for booking ' || COALESCE(v_booking.tracking_id, ''),
      NEW.refund_method, NEW.id::text, NEW.booking_id);

    -- Update financial summary
    SELECT COALESCE(SUM(debit), 0), COALESCE(SUM(credit), 0)
    INTO v_total_income, v_total_expense FROM public.transactions;
    SELECT COALESCE(SUM(amount), 0) INTO v_expense_total FROM public.expenses;
    v_total_expense := v_total_expense + v_expense_total;

    IF EXISTS (SELECT 1 FROM public.financial_summary LIMIT 1) THEN
      UPDATE public.financial_summary
      SET total_income = v_total_income, total_expense = v_total_expense,
          net_profit = v_total_income - v_total_expense, updated_at = now()
      WHERE id IS NOT NULL;
    ELSE
      INSERT INTO public.financial_summary (total_income, total_expense, net_profit)
      VALUES (v_total_income, v_total_expense, v_total_income - v_total_expense);
    END IF;

    NEW.processed_at := now();
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: on_settlement_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.on_settlement_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'completed' THEN
    IF NEW.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = balance + NEW.total_amount, updated_at = now()
      WHERE id = NEW.wallet_account_id;
    END IF;
    INSERT INTO public.transactions (type, category, amount, debit, credit, source_type, source_id, user_id, date, note, payment_method, reference)
    VALUES ('income', 'travel_settlement', NEW.total_amount, NEW.total_amount, 0, 'settlement', NEW.id,
      COALESCE(NEW.created_by, '00000000-0000-0000-0000-000000000000'::uuid),
      NEW.settlement_date, 'Settlement ' || NEW.settlement_no, NEW.payment_method, NEW.id::text);
  ELSIF TG_OP = 'DELETE' AND OLD.status = 'completed' THEN
    IF OLD.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = GREATEST(0, balance - OLD.total_amount), updated_at = now()
      WHERE id = OLD.wallet_account_id;
    END IF;
    DELETE FROM public.transactions WHERE reference = OLD.id::text AND source_type = 'settlement';
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: on_settlement_item_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.on_settlement_item_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.recalc_source_received(NEW.source_type, NEW.source_id);
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.source_type <> NEW.source_type OR OLD.source_id <> NEW.source_id THEN
      PERFORM public.recalc_source_received(OLD.source_type, OLD.source_id);
    END IF;
    PERFORM public.recalc_source_received(NEW.source_type, NEW.source_id);
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM public.recalc_source_received(OLD.source_type, OLD.source_id);
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: on_supplier_contract_payment(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.on_supplier_contract_payment() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_total_paid NUMERIC;
  v_contract_amount NUMERIC;
  v_supplier_name TEXT;
  v_wallet_balance NUMERIC;
  v_total_income NUMERIC;
  v_total_expense NUMERIC;
  v_expense_total NUMERIC;
BEGIN
  -- Wallet balance check on INSERT
  IF TG_OP = 'INSERT' AND NEW.wallet_account_id IS NOT NULL THEN
    SELECT balance INTO v_wallet_balance FROM public.accounts WHERE id = NEW.wallet_account_id;
    IF v_wallet_balance < NEW.amount THEN
      RAISE EXCEPTION 'Insufficient wallet balance. Available: %, Required: %', v_wallet_balance, NEW.amount;
    END IF;
    UPDATE public.accounts SET balance = balance - NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
  ELSIF TG_OP = 'DELETE' AND OLD.wallet_account_id IS NOT NULL THEN
    UPDATE public.accounts SET balance = balance + OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
  END IF;

  -- Update contract totals
  SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
  FROM public.supplier_contract_payments
  WHERE contract_id = COALESCE(NEW.contract_id, OLD.contract_id);

  SELECT contract_amount INTO v_contract_amount
  FROM public.supplier_contracts
  WHERE id = COALESCE(NEW.contract_id, OLD.contract_id);

  UPDATE public.supplier_contracts
  SET total_paid = v_total_paid,
      total_due = GREATEST(0, contract_amount - v_total_paid)
  WHERE id = COALESCE(NEW.contract_id, OLD.contract_id);

  -- Ledger entry
  SELECT agent_name INTO v_supplier_name FROM public.supplier_agents
  WHERE id = COALESCE(NEW.supplier_id, OLD.supplier_id);

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.transactions (type, category, amount, debit, credit, source_type, source_id, user_id, date, note, payment_method, reference)
    VALUES ('expense', 'supplier_contract_payment', NEW.amount, 0, NEW.amount, 'supplier', NEW.supplier_id,
      COALESCE(NEW.created_by, '00000000-0000-0000-0000-000000000000'::uuid),
      NEW.payment_date, 'Supplier contract payment to ' || COALESCE(v_supplier_name, 'Unknown'),
      NEW.payment_method, NEW.id::text);
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.transactions WHERE reference = OLD.id::text AND type = 'expense' AND category = 'supplier_contract_payment';
  END IF;

  -- Update financial summary
  SELECT COALESCE(SUM(debit), 0), COALESCE(SUM(credit), 0)
  INTO v_total_income, v_total_expense FROM public.transactions;

  SELECT COALESCE(SUM(amount), 0) INTO v_expense_total FROM public.expenses;
  v_total_expense := v_total_expense + v_expense_total;

  IF EXISTS (SELECT 1 FROM public.financial_summary LIMIT 1) THEN
    UPDATE public.financial_summary
    SET total_income = v_total_income, total_expense = v_total_expense,
        net_profit = v_total_income - v_total_expense, updated_at = now()
    WHERE id IS NOT NULL;
  ELSE
    INSERT INTO public.financial_summary (total_income, total_expense, net_profit)
    VALUES (v_total_income, v_total_expense, v_total_income - v_total_expense);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: on_supplier_payment_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.on_supplier_payment_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_agent_name TEXT;
  v_wallet_balance NUMERIC;
  v_total_income NUMERIC;
  v_total_expense NUMERIC;
  v_expense_total NUMERIC;
BEGIN
  IF TG_OP = 'INSERT' AND NEW.wallet_account_id IS NOT NULL THEN
    SELECT balance INTO v_wallet_balance FROM public.accounts WHERE id = NEW.wallet_account_id;
    IF v_wallet_balance < NEW.amount THEN
      RAISE EXCEPTION 'Insufficient wallet balance. Available: %, Required: %', v_wallet_balance, NEW.amount;
    END IF;
    UPDATE public.accounts SET balance = balance - NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = balance + OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
    END IF;
    IF NEW.wallet_account_id IS NOT NULL THEN
      SELECT balance INTO v_wallet_balance FROM public.accounts WHERE id = NEW.wallet_account_id;
      IF v_wallet_balance < NEW.amount THEN
        RAISE EXCEPTION 'Insufficient wallet balance. Available: %, Required: %', v_wallet_balance, NEW.amount;
      END IF;
      UPDATE public.accounts SET balance = balance - NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
    END IF;
  ELSIF TG_OP = 'DELETE' AND OLD.wallet_account_id IS NOT NULL THEN
    UPDATE public.accounts SET balance = balance + OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
  END IF;

  SELECT agent_name INTO v_agent_name FROM public.supplier_agents
  WHERE id = COALESCE(NEW.supplier_agent_id, OLD.supplier_agent_id);

  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.transactions (type, category, amount, debit, credit, source_type, source_id, user_id, date, note, payment_method, reference)
    VALUES ('expense', 'supplier_payment', NEW.amount, 0, NEW.amount, 'supplier', NEW.supplier_agent_id,
      COALESCE(NEW.recorded_by, '00000000-0000-0000-0000-000000000000'::uuid),
      NEW.date, 'Supplier payment to ' || COALESCE(v_agent_name, 'Unknown'),
      NEW.payment_method, NEW.id::text);
  ELSIF TG_OP = 'UPDATE' THEN
    DELETE FROM public.transactions WHERE reference = OLD.id::text AND type = 'expense' AND category = 'supplier_payment';
    INSERT INTO public.transactions (type, category, amount, debit, credit, source_type, source_id, user_id, date, note, payment_method, reference)
    VALUES ('expense', 'supplier_payment', NEW.amount, 0, NEW.amount, 'supplier', NEW.supplier_agent_id,
      COALESCE(NEW.recorded_by, '00000000-0000-0000-0000-000000000000'::uuid),
      NEW.date, 'Supplier payment to ' || COALESCE(v_agent_name, 'Unknown'),
      NEW.payment_method, NEW.id::text);
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.transactions WHERE reference = OLD.id::text AND type = 'expense' AND category = 'supplier_payment';
  END IF;

  SELECT COALESCE(SUM(debit), 0), COALESCE(SUM(credit), 0)
  INTO v_total_income, v_total_expense FROM public.transactions;

  SELECT COALESCE(SUM(amount), 0) INTO v_expense_total FROM public.expenses;
  v_total_expense := v_total_expense + v_expense_total;

  IF EXISTS (SELECT 1 FROM public.financial_summary LIMIT 1) THEN
    UPDATE public.financial_summary
    SET total_income = v_total_income, total_expense = v_total_expense,
        net_profit = v_total_income - v_total_expense, updated_at = now()
    WHERE id IS NOT NULL;
  ELSE
    INSERT INTO public.financial_summary (total_income, total_expense, net_profit)
    VALUES (v_total_income, v_total_expense, v_total_income - v_total_expense);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: on_ticket_refund_changed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.on_ticket_refund_changed() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'active' AND NEW.credit_amount_to_client > 0 THEN
    IF NEW.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = GREATEST(0, balance - NEW.credit_amount_to_client), updated_at = now()
      WHERE id = NEW.wallet_account_id;
    END IF;
    INSERT INTO public.transactions (type, category, amount, debit, credit, source_type, source_id, user_id, date, note, reference)
    VALUES ('expense', 'ticket_refund', NEW.credit_amount_to_client, 0, NEW.credit_amount_to_client,
      'ticket_refund', NEW.id,
      COALESCE(NEW.created_by, '00000000-0000-0000-0000-000000000000'::uuid),
      NEW.refund_date, 'Refund ' || NEW.invoice_no, NEW.id::text);
  ELSIF TG_OP = 'DELETE' AND OLD.status = 'active' AND OLD.credit_amount_to_client > 0 THEN
    IF OLD.wallet_account_id IS NOT NULL THEN
      UPDATE public.accounts SET balance = balance + OLD.credit_amount_to_client, updated_at = now()
      WHERE id = OLD.wallet_account_id;
    END IF;
    DELETE FROM public.transactions WHERE reference = OLD.id::text AND source_type = 'ticket_refund';
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: protect_admin_role(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.protect_admin_role() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  -- Protect the primary admin account (admin@rahekaba.com)
  IF OLD.user_id = '9c56194a-b0f9-4878-ac57-e97371acd199' AND OLD.role = 'admin' THEN
    RAISE EXCEPTION 'Cannot delete the primary admin role';
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: protect_admin_role_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.protect_admin_role_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF OLD.user_id = '9c56194a-b0f9-4878-ac57-e97371acd199' AND OLD.role = 'admin' AND NEW.role <> 'admin' THEN
    RAISE EXCEPTION 'Cannot change the primary admin role';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: recalc_source_received(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.recalc_source_received(p_source_type text, p_source_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_total NUMERIC;
BEGIN
  SELECT COALESCE(SUM(amount_applied), 0) INTO v_total
  FROM public.settlement_items
  WHERE source_type = p_source_type AND source_id = p_source_id;

  IF p_source_type = 'ticket' THEN
    UPDATE public.ticket_bookings SET received_amount = v_total WHERE id = p_source_id;
  ELSIF p_source_type = 'visa' THEN
    UPDATE public.visa_applications SET received_amount = v_total WHERE id = p_source_id;
  ELSIF p_source_type = 'refund' THEN
    UPDATE public.ticket_refunds SET bill_received = v_total WHERE id = p_source_id;
  END IF;
END;
$$;


--
-- Name: recalculate_wallet_balances(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.recalculate_wallet_balances() RETURNS TABLE(account_name text, old_balance numeric, new_balance numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  r RECORD;
  v_inflow NUMERIC;
  v_outflow NUMERIC;
  v_new_balance NUMERIC;
BEGIN
  FOR r IN SELECT id, name, balance FROM public.accounts WHERE type = 'asset' LOOP
    -- INFLOWS: customer payments (completed) + moallem payments + cashbook income
    SELECT COALESCE(SUM(amount), 0) INTO v_inflow
    FROM (
      SELECT amount FROM public.payments WHERE wallet_account_id = r.id AND status = 'completed'
      UNION ALL
      SELECT amount FROM public.moallem_payments WHERE wallet_account_id = r.id
      UNION ALL
      SELECT amount FROM public.daily_cashbook WHERE wallet_account_id = r.id AND type = 'income'
    ) inflows;

    -- OUTFLOWS: supplier payments + commission payments + supplier contract payments + expenses + cashbook expense
    SELECT COALESCE(SUM(amount), 0) INTO v_outflow
    FROM (
      SELECT amount FROM public.supplier_agent_payments WHERE wallet_account_id = r.id
      UNION ALL
      SELECT amount FROM public.moallem_commission_payments WHERE wallet_account_id = r.id
      UNION ALL
      SELECT amount FROM public.supplier_contract_payments WHERE wallet_account_id = r.id
      UNION ALL
      SELECT amount FROM public.expenses WHERE wallet_account_id = r.id
      UNION ALL
      SELECT amount FROM public.daily_cashbook WHERE wallet_account_id = r.id AND type = 'expense'
      UNION ALL
      SELECT refund_amount FROM public.refunds WHERE wallet_account_id = r.id AND status = 'processed'
    ) outflows;

    v_new_balance := v_inflow - v_outflow;

    account_name := r.name;
    old_balance := r.balance;
    new_balance := v_new_balance;
    RETURN NEXT;

    UPDATE public.accounts SET balance = v_new_balance, updated_at = now() WHERE id = r.id;
  END LOOP;
END;
$$;


--
-- Name: update_booking_commission_paid(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_booking_commission_paid() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_booking_id UUID;
  v_total_paid NUMERIC;
  v_total_commission NUMERIC;
BEGIN
  v_booking_id := COALESCE(NEW.booking_id, OLD.booking_id);
  
  IF v_booking_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
  FROM public.moallem_commission_payments
  WHERE booking_id = v_booking_id;

  SELECT COALESCE(total_commission, 0) INTO v_total_commission
  FROM public.bookings WHERE id = v_booking_id;

  UPDATE public.bookings
  SET commission_paid = v_total_paid,
      commission_due = GREATEST(0, v_total_commission - v_total_paid)
  WHERE id = v_booking_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: update_booking_moallem_paid(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_booking_moallem_paid() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_booking_id UUID;
  v_total_paid NUMERIC;
  v_total_amount NUMERIC;
BEGIN
  v_booking_id := COALESCE(NEW.booking_id, OLD.booking_id);
  
  IF v_booking_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- Sum all moallem payments for this booking
  SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
  FROM public.moallem_payments
  WHERE booking_id = v_booking_id;

  -- Get booking total_amount
  SELECT COALESCE(total_amount, 0) INTO v_total_amount
  FROM public.bookings WHERE id = v_booking_id;

  -- Update booking moallem fields
  UPDATE public.bookings
  SET paid_by_moallem = v_total_paid,
      moallem_due = GREATEST(0, v_total_amount - v_total_paid)
  WHERE id = v_booking_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: update_booking_paid_amount(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_booking_paid_amount() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_total_paid NUMERIC;
  v_total_amount NUMERIC;
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
  FROM public.payments
  WHERE booking_id = COALESCE(NEW.booking_id, OLD.booking_id)
    AND status = 'completed';

  SELECT total_amount INTO v_total_amount
  FROM public.bookings
  WHERE id = COALESCE(NEW.booking_id, OLD.booking_id);

  v_total_paid := GREATEST(0, LEAST(v_total_paid, v_total_amount));

  UPDATE public.bookings
  SET paid_amount = v_total_paid,
      due_amount = GREATEST(0, v_total_amount - v_total_paid),
      status = CASE WHEN v_total_paid >= v_total_amount THEN 'completed' ELSE status END
  WHERE id = COALESCE(NEW.booking_id, OLD.booking_id);

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: update_booking_supplier_paid(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_booking_supplier_paid() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_booking_id UUID;
  v_total_paid NUMERIC;
  v_total_cost NUMERIC;
BEGIN
  v_booking_id := COALESCE(NEW.booking_id, OLD.booking_id);
  
  IF v_booking_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- Sum all supplier payments for this booking
  SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
  FROM public.supplier_agent_payments
  WHERE booking_id = v_booking_id;

  -- Get booking total_cost
  SELECT COALESCE(total_cost, 0) INTO v_total_cost
  FROM public.bookings WHERE id = v_booking_id;

  -- Update booking supplier fields
  UPDATE public.bookings
  SET paid_to_supplier = v_total_paid,
      supplier_due = GREATEST(0, v_total_cost - v_total_paid)
  WHERE id = v_booking_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: update_moallem_on_booking(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_moallem_on_booking() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_total_amount NUMERIC;
  v_total_paid NUMERIC;
  v_hajji_count INTEGER;
  v_moallem_id UUID;
BEGIN
  -- Handle the moallem that needs updating
  v_moallem_id := COALESCE(NEW.moallem_id, OLD.moallem_id);
  
  IF v_moallem_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- If moallem changed on UPDATE, also update the old moallem
  IF TG_OP = 'UPDATE' AND OLD.moallem_id IS NOT NULL AND OLD.moallem_id IS DISTINCT FROM NEW.moallem_id THEN
    SELECT COALESCE(SUM(total_amount), 0), COALESCE(SUM(paid_amount), 0), COALESCE(SUM(num_travelers), 0)
    INTO v_total_amount, v_total_paid, v_hajji_count
    FROM public.bookings WHERE moallem_id = OLD.moallem_id;

    UPDATE public.moallems SET
      total_due = GREATEST(0, v_total_amount - v_total_paid),
      updated_at = now()
    WHERE id = OLD.moallem_id;
  END IF;

  -- Update the current moallem
  SELECT COALESCE(SUM(total_amount), 0), COALESCE(SUM(paid_amount), 0), COALESCE(SUM(num_travelers), 0)
  INTO v_total_amount, v_total_paid, v_hajji_count
  FROM public.bookings WHERE moallem_id = v_moallem_id;

  UPDATE public.moallems SET
    total_due = GREATEST(0, v_total_amount - v_total_paid),
    updated_at = now()
  WHERE id = v_moallem_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: update_moallem_on_deposit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_moallem_on_deposit() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_total_deposit NUMERIC;
  v_total_amount NUMERIC;
  v_total_paid NUMERIC;
  v_moallem_id UUID;
BEGIN
  v_moallem_id := COALESCE(NEW.moallem_id, OLD.moallem_id);

  SELECT COALESCE(SUM(amount), 0) INTO v_total_deposit
  FROM public.moallem_payments WHERE moallem_id = v_moallem_id;

  SELECT COALESCE(SUM(total_amount), 0), COALESCE(SUM(paid_amount), 0)
  INTO v_total_amount, v_total_paid
  FROM public.bookings WHERE moallem_id = v_moallem_id;

  UPDATE public.moallems SET
    total_deposit = v_total_deposit,
    total_due = GREATEST(0, v_total_amount - v_total_paid),
    updated_at = now()
  WHERE id = v_moallem_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- Name: update_wallet_on_cashbook_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_wallet_on_cashbook_delete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF OLD.wallet_account_id IS NOT NULL THEN
    IF OLD.type = 'income' THEN
      UPDATE accounts SET balance = balance - OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
    ELSIF OLD.type = 'expense' THEN
      UPDATE accounts SET balance = balance + OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
    END IF;
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: update_wallet_on_cashbook_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_wallet_on_cashbook_insert() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.wallet_account_id IS NOT NULL THEN
    IF NEW.type = 'income' THEN
      UPDATE accounts SET balance = balance + NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
    ELSIF NEW.type = 'expense' THEN
      UPDATE accounts SET balance = balance - NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: update_wallet_on_cashbook_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_wallet_on_cashbook_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF OLD.wallet_account_id IS NOT NULL THEN
    IF OLD.type = 'income' THEN
      UPDATE accounts SET balance = balance - OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
    ELSIF OLD.type = 'expense' THEN
      UPDATE accounts SET balance = balance + OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
    END IF;
  END IF;
  IF NEW.wallet_account_id IS NOT NULL THEN
    IF NEW.type = 'income' THEN
      UPDATE accounts SET balance = balance + NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
    ELSIF NEW.type = 'expense' THEN
      UPDATE accounts SET balance = balance - NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: update_wallet_on_expense_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_wallet_on_expense_delete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF OLD.wallet_account_id IS NOT NULL THEN
    UPDATE accounts SET balance = balance + OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: update_wallet_on_expense_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_wallet_on_expense_insert() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.wallet_account_id IS NOT NULL THEN
    UPDATE accounts SET balance = balance - NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: update_wallet_on_moallem_payment_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_wallet_on_moallem_payment_insert() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.wallet_account_id IS NOT NULL THEN
    UPDATE accounts SET balance = balance + NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: update_wallet_on_payment_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_wallet_on_payment_delete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF OLD.wallet_account_id IS NOT NULL AND OLD.status = 'completed' THEN
    UPDATE accounts SET balance = balance - OLD.amount, updated_at = now() WHERE id = OLD.wallet_account_id;
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: update_wallet_on_payment_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_wallet_on_payment_insert() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.wallet_account_id IS NOT NULL AND NEW.status = 'completed' THEN
    UPDATE accounts SET balance = balance + NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: update_wallet_on_supplier_payment_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_wallet_on_supplier_payment_insert() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.wallet_account_id IS NOT NULL THEN
    UPDATE accounts SET balance = balance - NEW.amount, updated_at = now() WHERE id = NEW.wallet_account_id;
  END IF;
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    balance numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT accounts_balance_non_negative CHECK ((balance >= (0)::numeric)),
    CONSTRAINT accounts_type_check CHECK ((type = ANY (ARRAY['income'::text, 'expense'::text, 'asset'::text, 'liability'::text])))
);


--
-- Name: admin_2fa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_2fa (
    user_id uuid NOT NULL,
    sms_enabled boolean DEFAULT false NOT NULL,
    sms_phone text,
    totp_enabled boolean DEFAULT false NOT NULL,
    totp_secret text,
    totp_secret_pending text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: admin_2fa_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_2fa_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    code text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    actor_id uuid,
    actor_email text,
    actor_role text,
    action text NOT NULL,
    entity_type text,
    entity_id text,
    method text,
    path text,
    status_code integer,
    ip_address text,
    user_agent text,
    changes jsonb DEFAULT '{}'::jsonb,
    metadata jsonb DEFAULT '{}'::jsonb
);


--
-- Name: blog_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blog_posts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    slug text NOT NULL,
    content text DEFAULT ''::text NOT NULL,
    excerpt text,
    image_url text,
    status text DEFAULT 'draft'::text NOT NULL,
    author_id uuid,
    tags text[] DEFAULT '{}'::text[],
    published_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: booking_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booking_id uuid NOT NULL,
    user_id uuid NOT NULL,
    document_type text NOT NULL,
    file_name text NOT NULL,
    file_path text NOT NULL,
    file_size integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT booking_documents_document_type_check CHECK ((document_type = ANY (ARRAY['passport'::text, 'nid'::text, 'photo'::text, 'other'::text])))
);


--
-- Name: booking_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booking_id uuid NOT NULL,
    full_name text NOT NULL,
    passport_number text,
    package_id uuid,
    selling_price numeric DEFAULT 0 NOT NULL,
    discount numeric DEFAULT 0 NOT NULL,
    final_price numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: bookings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tracking_id text DEFAULT ('MTH-'::text || upper(substr((gen_random_uuid())::text, 1, 8))) NOT NULL,
    user_id uuid,
    package_id uuid NOT NULL,
    installment_plan_id uuid,
    total_amount numeric(12,2) NOT NULL,
    paid_amount numeric(12,2) DEFAULT 0 NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    num_travelers integer DEFAULT 1 NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    guest_name text,
    guest_phone text,
    guest_email text,
    guest_address text,
    guest_passport text,
    due_amount numeric DEFAULT 0,
    moallem_id uuid,
    supplier_agent_id uuid,
    cost_price_per_person numeric DEFAULT 0,
    total_cost numeric DEFAULT 0,
    selling_price_per_person numeric DEFAULT 0,
    extra_expense numeric DEFAULT 0,
    profit_amount numeric DEFAULT 0,
    paid_to_supplier numeric DEFAULT 0 NOT NULL,
    supplier_due numeric DEFAULT 0 NOT NULL,
    paid_by_moallem numeric DEFAULT 0 NOT NULL,
    moallem_due numeric DEFAULT 0 NOT NULL,
    commission_per_person numeric DEFAULT 0 NOT NULL,
    total_commission numeric DEFAULT 0 NOT NULL,
    commission_paid numeric DEFAULT 0 NOT NULL,
    commission_due numeric DEFAULT 0 NOT NULL,
    booking_type text DEFAULT 'individual'::text NOT NULL,
    discount numeric DEFAULT 0 NOT NULL,
    CONSTRAINT bookings_paid_amount_non_negative CHECK ((paid_amount >= (0)::numeric)),
    CONSTRAINT bookings_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'in_progress'::text, 'completed'::text, 'cancelled'::text])))
);


--
-- Name: cancellation_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cancellation_policies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    refund_type text DEFAULT 'percentage'::text NOT NULL,
    refund_value numeric DEFAULT 0 NOT NULL,
    min_days_before_departure integer DEFAULT 0,
    is_default boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT cancellation_policies_refund_type_check CHECK ((refund_type = ANY (ARRAY['percentage'::text, 'flat'::text])))
);


--
-- Name: cms_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cms_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    section_key text NOT NULL,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    note text
);


--
-- Name: company_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.company_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    setting_key text NOT NULL,
    setting_value jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid
);


--
-- Name: daily_cashbook; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_cashbook (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    date date DEFAULT CURRENT_DATE NOT NULL,
    type text NOT NULL,
    description text NOT NULL,
    amount numeric NOT NULL,
    category text DEFAULT 'other'::text NOT NULL,
    wallet_account_id uuid,
    payment_method text DEFAULT 'cash'::text,
    notes text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT daily_cashbook_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT daily_cashbook_type_check CHECK ((type = ANY (ARRAY['income'::text, 'expense'::text])))
);


--
-- Name: expenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.expenses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    amount numeric NOT NULL,
    category text NOT NULL,
    booking_id uuid,
    date date DEFAULT CURRENT_DATE NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    customer_id uuid,
    package_id uuid,
    expense_type text DEFAULT 'other'::text NOT NULL,
    wallet_account_id uuid,
    CONSTRAINT expenses_amount_positive CHECK ((amount > (0)::numeric))
);


--
-- Name: financial_summary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.financial_summary (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    total_income numeric DEFAULT 0 NOT NULL,
    total_expense numeric DEFAULT 0 NOT NULL,
    net_profit numeric DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: hotel_bookings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hotel_bookings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    hotel_id uuid NOT NULL,
    room_id uuid NOT NULL,
    check_in date NOT NULL,
    check_out date NOT NULL,
    guests integer DEFAULT 1 NOT NULL,
    total_price numeric(10,2) NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT hotel_bookings_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'cancelled'::text, 'completed'::text])))
);


--
-- Name: hotel_rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hotel_rooms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    hotel_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    capacity integer DEFAULT 2 NOT NULL,
    price_per_night numeric(10,2) NOT NULL,
    amenities jsonb DEFAULT '[]'::jsonb,
    image_url text,
    is_available boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: hotels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hotels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    location text NOT NULL,
    city text DEFAULT 'Makkah'::text NOT NULL,
    description text,
    star_rating integer,
    distance_to_haram text,
    amenities jsonb DEFAULT '[]'::jsonb,
    image_url text,
    gallery jsonb DEFAULT '[]'::jsonb,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT hotels_star_rating_check CHECK (((star_rating >= 1) AND (star_rating <= 5)))
);


--
-- Name: installment_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.installment_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    num_installments integer NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: moallem_commission_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moallem_commission_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    moallem_id uuid NOT NULL,
    booking_id uuid,
    amount numeric NOT NULL,
    payment_method text DEFAULT 'cash'::text,
    date date DEFAULT CURRENT_DATE NOT NULL,
    notes text,
    wallet_account_id uuid,
    recorded_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: moallem_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moallem_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    moallem_id uuid NOT NULL,
    description text NOT NULL,
    quantity numeric DEFAULT 1 NOT NULL,
    unit_price numeric DEFAULT 0 NOT NULL,
    total_amount numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: moallem_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moallem_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    moallem_id uuid NOT NULL,
    amount numeric NOT NULL,
    payment_method text DEFAULT 'cash'::text,
    date date DEFAULT CURRENT_DATE NOT NULL,
    notes text,
    wallet_account_id uuid,
    recorded_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    booking_id uuid,
    receipt_file_path text
);


--
-- Name: moallems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moallems (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    phone text,
    address text,
    nid_number text,
    contract_date date,
    notes text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    total_deposit numeric DEFAULT 0 NOT NULL,
    total_due numeric DEFAULT 0 NOT NULL,
    contracted_hajji integer DEFAULT 0 NOT NULL,
    contracted_amount numeric DEFAULT 0 NOT NULL
);


--
-- Name: notification_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    booking_id uuid,
    payment_id uuid,
    event_type text NOT NULL,
    channel text NOT NULL,
    recipient text NOT NULL,
    subject text,
    message text NOT NULL,
    status text DEFAULT 'sent'::text NOT NULL,
    error_detail text,
    sent_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: notification_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_key text NOT NULL,
    event_label text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    email_enabled boolean DEFAULT true NOT NULL,
    sms_enabled boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid
);


--
-- Name: online_payment_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.online_payment_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tran_id text NOT NULL,
    booking_id uuid,
    user_id uuid,
    customer_phone text,
    amount numeric NOT NULL,
    currency text DEFAULT 'BDT'::text NOT NULL,
    status text DEFAULT 'initiated'::text NOT NULL,
    gateway text DEFAULT 'sslcommerz'::text NOT NULL,
    gateway_response jsonb,
    payment_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: otp_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.otp_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    phone text NOT NULL,
    code text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.otp_codes FORCE ROW LEVEL SECURITY;


--
-- Name: packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.packages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    description text,
    price numeric(12,2) NOT NULL,
    duration_days integer,
    features jsonb DEFAULT '[]'::jsonb,
    image_url text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    start_date date,
    services jsonb DEFAULT '[]'::jsonb,
    expiry_date date,
    status text DEFAULT 'active'::text NOT NULL,
    show_on_website boolean DEFAULT true NOT NULL,
    rating numeric DEFAULT 4.9 NOT NULL,
    highlight_tag text,
    CONSTRAINT packages_type_check CHECK ((type = ANY (ARRAY['hajj'::text, 'umrah'::text, 'visa'::text, 'hotel'::text, 'transport'::text, 'ziyara'::text, 'tour'::text, 'air_ticket'::text, 'emergency'::text, 'other'::text])))
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booking_id uuid NOT NULL,
    user_id uuid NOT NULL,
    amount numeric(12,2) NOT NULL,
    installment_number integer,
    payment_method text DEFAULT 'manual'::text,
    status text DEFAULT 'pending'::text NOT NULL,
    due_date date,
    paid_at timestamp with time zone,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    transaction_id text,
    customer_id uuid,
    wallet_account_id uuid,
    receipt_file_path text,
    CONSTRAINT payments_amount_positive CHECK ((amount > (0)::numeric)),
    CONSTRAINT payments_payment_method_check CHECK ((payment_method = ANY (ARRAY['cash'::text, 'bkash'::text, 'nagad'::text, 'bank'::text, 'manual'::text, 'online'::text, 'bank_transfer'::text]))),
    CONSTRAINT payments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'failed'::text, 'refunded'::text])))
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    full_name text,
    phone text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    address text,
    passport_number text,
    email text,
    nid_number text,
    date_of_birth date,
    emergency_contact text,
    notes text,
    status text DEFAULT 'active'::text NOT NULL
);


--
-- Name: refund_invoice_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.refund_invoice_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refunds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refunds (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booking_id uuid NOT NULL,
    policy_id uuid,
    original_amount numeric DEFAULT 0 NOT NULL,
    refund_amount numeric DEFAULT 0 NOT NULL,
    deduction_amount numeric DEFAULT 0 NOT NULL,
    refund_method text DEFAULT 'cash'::text,
    wallet_account_id uuid,
    reason text,
    status text DEFAULT 'pending'::text NOT NULL,
    processed_by uuid,
    processed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT refunds_refund_method_check CHECK ((refund_method = ANY (ARRAY['cash'::text, 'bkash'::text, 'nagad'::text, 'bank'::text, 'bank_transfer'::text]))),
    CONSTRAINT refunds_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'processed'::text, 'rejected'::text])))
);


--
-- Name: settlement_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settlement_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    settlement_id uuid NOT NULL,
    source_type text NOT NULL,
    source_id uuid NOT NULL,
    invoice_no text,
    amount_applied numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: settlement_no_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settlement_no_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settlements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settlements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    settlement_no text DEFAULT public.gen_settlement_no() NOT NULL,
    settlement_date date DEFAULT CURRENT_DATE NOT NULL,
    payer_name text,
    payment_method text DEFAULT 'cash'::text NOT NULL,
    total_amount numeric DEFAULT 0 NOT NULL,
    wallet_account_id uuid,
    notes text,
    receipt_file_path text,
    status text DEFAULT 'completed'::text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: site_content; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_content (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    section_key text NOT NULL,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid
);


--
-- Name: supplier_agent_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supplier_agent_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    supplier_agent_id uuid NOT NULL,
    description text NOT NULL,
    quantity numeric DEFAULT 1 NOT NULL,
    unit_price numeric DEFAULT 0 NOT NULL,
    total_amount numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: supplier_agent_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supplier_agent_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    supplier_agent_id uuid NOT NULL,
    amount numeric NOT NULL,
    payment_method text DEFAULT 'cash'::text,
    date date DEFAULT CURRENT_DATE NOT NULL,
    notes text,
    wallet_account_id uuid,
    recorded_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    booking_id uuid,
    receipt_file_path text
);


--
-- Name: supplier_agents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supplier_agents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agent_name text NOT NULL,
    company_name text,
    phone text,
    address text,
    notes text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    contract_date date,
    contracted_hajji integer DEFAULT 0 NOT NULL,
    contracted_amount numeric DEFAULT 0 NOT NULL
);


--
-- Name: supplier_contract_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supplier_contract_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    supplier_id uuid NOT NULL,
    contract_id uuid NOT NULL,
    amount numeric NOT NULL,
    payment_method text DEFAULT 'cash'::text,
    payment_date date DEFAULT CURRENT_DATE NOT NULL,
    note text,
    wallet_account_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: supplier_contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supplier_contracts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    supplier_id uuid NOT NULL,
    pilgrim_count integer DEFAULT 0 NOT NULL,
    contract_amount numeric DEFAULT 0 NOT NULL,
    total_paid numeric DEFAULT 0 NOT NULL,
    total_due numeric DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: ticket_bookings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticket_bookings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_no text DEFAULT public.gen_ticket_invoice_no() NOT NULL,
    staff_name text,
    passenger_name text NOT NULL,
    booking_ref text,
    vendor_name text,
    vendor_id uuid,
    billing_name text,
    client_reference text,
    issue_date date DEFAULT CURRENT_DATE NOT NULL,
    terms_of_charge text DEFAULT 'newly_issue'::text NOT NULL,
    customer_billing_amount numeric DEFAULT 0 NOT NULL,
    our_cost numeric DEFAULT 0 NOT NULL,
    received_amount numeric DEFAULT 0 NOT NULL,
    customer_due numeric DEFAULT 0 NOT NULL,
    profit numeric DEFAULT 0 NOT NULL,
    payment_status text DEFAULT 'due'::text NOT NULL,
    departure_date date,
    arrival_date date,
    route text,
    expected_collection_date date,
    remarks text,
    bill_correction_amount numeric,
    status text DEFAULT 'active'::text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: ticket_invoice_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ticket_invoice_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ticket_refunds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticket_refunds (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_no text DEFAULT public.gen_refund_invoice_no() NOT NULL,
    ticket_booking_id uuid,
    staff_name text,
    passenger_name text NOT NULL,
    booking_ref text,
    vendor_name text,
    vendor_id uuid,
    billing_name text,
    client_reference text,
    refund_date date DEFAULT CURRENT_DATE NOT NULL,
    terms_of_charge text DEFAULT 'refund_charge'::text NOT NULL,
    billing_amount_was numeric DEFAULT 0 NOT NULL,
    customer_refund_charge numeric DEFAULT 0 NOT NULL,
    our_refund_charge numeric DEFAULT 0 NOT NULL,
    refund_back_from_vendor numeric DEFAULT 0 NOT NULL,
    credit_amount_to_client numeric DEFAULT 0 NOT NULL,
    ticket_costing_was numeric DEFAULT 0 NOT NULL,
    profit numeric DEFAULT 0 NOT NULL,
    bill_received numeric DEFAULT 0 NOT NULL,
    due numeric DEFAULT 0 NOT NULL,
    credit_status text DEFAULT 'pending'::text NOT NULL,
    route text,
    remarks text,
    wallet_account_id uuid,
    status text DEFAULT 'active'::text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type text NOT NULL,
    category text NOT NULL,
    amount numeric NOT NULL,
    booking_id uuid,
    user_id uuid NOT NULL,
    date date DEFAULT CURRENT_DATE NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    payment_method text,
    customer_id uuid,
    reference text,
    debit numeric DEFAULT 0 NOT NULL,
    credit numeric DEFAULT 0 NOT NULL,
    source_type text DEFAULT 'other'::text NOT NULL,
    source_id uuid,
    CONSTRAINT transactions_type_check CHECK ((type = ANY (ARRAY['income'::text, 'expense'::text])))
);


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    role public.app_role DEFAULT 'user'::public.app_role NOT NULL
);


--
-- Name: v_booking_profit; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_booking_profit WITH (security_invoker='on') AS
 SELECT b.id AS booking_id,
    b.tracking_id,
    b.guest_name,
    b.status,
    b.num_travelers,
    b.selling_price_per_person,
    b.cost_price_per_person,
    b.total_amount,
    b.total_cost,
    b.extra_expense,
    b.profit_amount,
    b.paid_amount,
    b.due_amount,
    b.paid_to_supplier,
    b.supplier_due,
    b.paid_by_moallem,
    b.moallem_due,
    b.moallem_id,
    b.commission_per_person,
    b.total_commission,
    b.commission_paid,
    b.commission_due,
    p.name AS package_name,
    p.type AS package_type,
    b.package_id,
    COALESCE(( SELECT sum(pay.amount) AS sum
           FROM public.payments pay
          WHERE ((pay.booking_id = b.id) AND (pay.status = 'completed'::text))), (0)::numeric) AS total_payments,
    COALESCE(( SELECT sum(e.amount) AS sum
           FROM public.expenses e
          WHERE (e.booking_id = b.id)), (0)::numeric) AS total_expenses
   FROM (public.bookings b
     LEFT JOIN public.packages p ON ((b.package_id = p.id)));


--
-- Name: v_customer_profit; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_customer_profit WITH (security_invoker='on') AS
 SELECT pr.id AS customer_id,
    pr.full_name,
    pr.phone,
    count(b.id) AS total_bookings,
    COALESCE(sum(b.total_amount), (0)::numeric) AS total_payments,
    (COALESCE(sum(b.total_cost), (0)::numeric) + COALESCE(sum(b.extra_expense), (0)::numeric)) AS total_expenses,
    COALESCE(sum(b.profit_amount), (0)::numeric) AS profit
   FROM (public.profiles pr
     LEFT JOIN public.bookings b ON ((b.user_id = pr.user_id)))
  GROUP BY pr.id, pr.full_name, pr.phone;


--
-- Name: v_package_profit; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_package_profit WITH (security_invoker='on') AS
 SELECT p.id AS package_id,
    p.name AS package_name,
    p.type AS package_type,
    p.price AS package_price,
    count(b.id) AS total_bookings,
    COALESCE(sum(b.total_amount), (0)::numeric) AS total_revenue,
    COALESCE(sum(b.profit_amount), (0)::numeric) AS profit,
    COALESCE(sum(b.total_cost), (0)::numeric) AS total_expenses
   FROM (public.packages p
     LEFT JOIN public.bookings b ON ((b.package_id = p.id)))
  GROUP BY p.id, p.name, p.type, p.price;


--
-- Name: visa_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visa_applications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_no text DEFAULT public.gen_visa_invoice_no() NOT NULL,
    staff_name text,
    applicant_name text NOT NULL,
    passport_number text,
    country_name text NOT NULL,
    vendor_name text,
    vendor_id uuid,
    billing_name text,
    client_reference text,
    application_date date DEFAULT CURRENT_DATE NOT NULL,
    billing_amount numeric DEFAULT 0 NOT NULL,
    our_cost numeric DEFAULT 0 NOT NULL,
    received_amount numeric DEFAULT 0 NOT NULL,
    customer_due numeric DEFAULT 0 NOT NULL,
    profit numeric DEFAULT 0 NOT NULL,
    visa_status text DEFAULT 'pending'::text NOT NULL,
    payment_status text DEFAULT 'due'::text NOT NULL,
    submission_date date,
    vendor_delivery_date date,
    client_delivery_date date,
    expected_collection_date date,
    remarks text,
    status text DEFAULT 'active'::text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: visa_invoice_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.visa_invoice_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: admin_2fa_codes admin_2fa_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_2fa_codes
    ADD CONSTRAINT admin_2fa_codes_pkey PRIMARY KEY (id);


--
-- Name: admin_2fa admin_2fa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_2fa
    ADD CONSTRAINT admin_2fa_pkey PRIMARY KEY (user_id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: blog_posts blog_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_posts
    ADD CONSTRAINT blog_posts_pkey PRIMARY KEY (id);


--
-- Name: blog_posts blog_posts_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blog_posts
    ADD CONSTRAINT blog_posts_slug_key UNIQUE (slug);


--
-- Name: booking_documents booking_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_documents
    ADD CONSTRAINT booking_documents_pkey PRIMARY KEY (id);


--
-- Name: booking_members booking_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_members
    ADD CONSTRAINT booking_members_pkey PRIMARY KEY (id);


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: bookings bookings_tracking_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_tracking_id_key UNIQUE (tracking_id);


--
-- Name: cancellation_policies cancellation_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancellation_policies
    ADD CONSTRAINT cancellation_policies_pkey PRIMARY KEY (id);


--
-- Name: cms_versions cms_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cms_versions
    ADD CONSTRAINT cms_versions_pkey PRIMARY KEY (id);


--
-- Name: company_settings company_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_settings
    ADD CONSTRAINT company_settings_pkey PRIMARY KEY (id);


--
-- Name: company_settings company_settings_setting_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_settings
    ADD CONSTRAINT company_settings_setting_key_key UNIQUE (setting_key);


--
-- Name: daily_cashbook daily_cashbook_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_cashbook
    ADD CONSTRAINT daily_cashbook_pkey PRIMARY KEY (id);


--
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- Name: financial_summary financial_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_summary
    ADD CONSTRAINT financial_summary_pkey PRIMARY KEY (id);


--
-- Name: hotel_bookings hotel_bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hotel_bookings
    ADD CONSTRAINT hotel_bookings_pkey PRIMARY KEY (id);


--
-- Name: hotel_rooms hotel_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hotel_rooms
    ADD CONSTRAINT hotel_rooms_pkey PRIMARY KEY (id);


--
-- Name: hotels hotels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hotels
    ADD CONSTRAINT hotels_pkey PRIMARY KEY (id);


--
-- Name: installment_plans installment_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.installment_plans
    ADD CONSTRAINT installment_plans_pkey PRIMARY KEY (id);


--
-- Name: moallem_commission_payments moallem_commission_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moallem_commission_payments
    ADD CONSTRAINT moallem_commission_payments_pkey PRIMARY KEY (id);


--
-- Name: moallem_items moallem_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moallem_items
    ADD CONSTRAINT moallem_items_pkey PRIMARY KEY (id);


--
-- Name: moallem_payments moallem_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moallem_payments
    ADD CONSTRAINT moallem_payments_pkey PRIMARY KEY (id);


--
-- Name: moallems moallems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moallems
    ADD CONSTRAINT moallems_pkey PRIMARY KEY (id);


--
-- Name: notification_logs notification_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_logs
    ADD CONSTRAINT notification_logs_pkey PRIMARY KEY (id);


--
-- Name: notification_settings notification_settings_event_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_settings
    ADD CONSTRAINT notification_settings_event_key_key UNIQUE (event_key);


--
-- Name: notification_settings notification_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_settings
    ADD CONSTRAINT notification_settings_pkey PRIMARY KEY (id);


--
-- Name: online_payment_sessions online_payment_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_payment_sessions
    ADD CONSTRAINT online_payment_sessions_pkey PRIMARY KEY (id);


--
-- Name: online_payment_sessions online_payment_sessions_tran_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_payment_sessions
    ADD CONSTRAINT online_payment_sessions_tran_id_key UNIQUE (tran_id);


--
-- Name: otp_codes otp_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.otp_codes
    ADD CONSTRAINT otp_codes_pkey PRIMARY KEY (id);


--
-- Name: packages packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT packages_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_user_id_key UNIQUE (user_id);


--
-- Name: refunds refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_pkey PRIMARY KEY (id);


--
-- Name: settlement_items settlement_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settlement_items
    ADD CONSTRAINT settlement_items_pkey PRIMARY KEY (id);


--
-- Name: settlements settlements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_pkey PRIMARY KEY (id);


--
-- Name: settlements settlements_settlement_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_settlement_no_key UNIQUE (settlement_no);


--
-- Name: site_content site_content_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_content
    ADD CONSTRAINT site_content_pkey PRIMARY KEY (id);


--
-- Name: site_content site_content_section_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_content
    ADD CONSTRAINT site_content_section_key_key UNIQUE (section_key);


--
-- Name: supplier_agent_items supplier_agent_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_agent_items
    ADD CONSTRAINT supplier_agent_items_pkey PRIMARY KEY (id);


--
-- Name: supplier_agent_payments supplier_agent_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_agent_payments
    ADD CONSTRAINT supplier_agent_payments_pkey PRIMARY KEY (id);


--
-- Name: supplier_agents supplier_agents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_agents
    ADD CONSTRAINT supplier_agents_pkey PRIMARY KEY (id);


--
-- Name: supplier_contract_payments supplier_contract_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_contract_payments
    ADD CONSTRAINT supplier_contract_payments_pkey PRIMARY KEY (id);


--
-- Name: supplier_contracts supplier_contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_contracts
    ADD CONSTRAINT supplier_contracts_pkey PRIMARY KEY (id);


--
-- Name: ticket_bookings ticket_bookings_invoice_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_bookings
    ADD CONSTRAINT ticket_bookings_invoice_no_key UNIQUE (invoice_no);


--
-- Name: ticket_bookings ticket_bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_bookings
    ADD CONSTRAINT ticket_bookings_pkey PRIMARY KEY (id);


--
-- Name: ticket_refunds ticket_refunds_invoice_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_refunds
    ADD CONSTRAINT ticket_refunds_invoice_no_key UNIQUE (invoice_no);


--
-- Name: ticket_refunds ticket_refunds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_refunds
    ADD CONSTRAINT ticket_refunds_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_user_id_role_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_role_key UNIQUE (user_id, role);


--
-- Name: visa_applications visa_applications_invoice_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visa_applications
    ADD CONSTRAINT visa_applications_invoice_no_key UNIQUE (invoice_no);


--
-- Name: visa_applications visa_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visa_applications
    ADD CONSTRAINT visa_applications_pkey PRIMARY KEY (id);


--
-- Name: idx_admin_2fa_codes_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_admin_2fa_codes_user ON public.admin_2fa_codes USING btree (user_id, created_at DESC);


--
-- Name: idx_audit_logs_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);


--
-- Name: idx_audit_logs_actor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_actor ON public.audit_logs USING btree (actor_id);


--
-- Name: idx_audit_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_created_at ON public.audit_logs USING btree (created_at DESC);


--
-- Name: idx_audit_logs_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id);


--
-- Name: idx_blog_posts_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_blog_posts_slug ON public.blog_posts USING btree (slug);


--
-- Name: idx_blog_posts_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_blog_posts_status ON public.blog_posts USING btree (status);


--
-- Name: idx_cms_versions_section; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cms_versions_section ON public.cms_versions USING btree (section_key, created_at DESC);


--
-- Name: idx_expenses_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_expenses_category ON public.expenses USING btree (category);


--
-- Name: idx_expenses_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_expenses_date ON public.expenses USING btree (date);


--
-- Name: idx_notification_logs_booking; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_logs_booking ON public.notification_logs USING btree (booking_id);


--
-- Name: idx_notification_logs_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_logs_created ON public.notification_logs USING btree (created_at DESC);


--
-- Name: idx_notification_logs_event; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_logs_event ON public.notification_logs USING btree (event_type);


--
-- Name: idx_notification_logs_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_logs_user ON public.notification_logs USING btree (user_id);


--
-- Name: idx_ops_booking; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ops_booking ON public.online_payment_sessions USING btree (booking_id);


--
-- Name: idx_ops_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ops_status ON public.online_payment_sessions USING btree (status);


--
-- Name: idx_otp_codes_phone_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_otp_codes_phone_expires ON public.otp_codes USING btree (phone, expires_at);


--
-- Name: idx_packages_show_on_website; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_packages_show_on_website ON public.packages USING btree (show_on_website);


--
-- Name: idx_packages_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_packages_status ON public.packages USING btree (status);


--
-- Name: idx_profiles_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_status ON public.profiles USING btree (status);


--
-- Name: idx_settlement_items_settlement; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settlement_items_settlement ON public.settlement_items USING btree (settlement_id);


--
-- Name: idx_settlement_items_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settlement_items_source ON public.settlement_items USING btree (source_type, source_id);


--
-- Name: idx_settlements_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settlements_date ON public.settlements USING btree (settlement_date);


--
-- Name: idx_settlements_no; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_settlements_no ON public.settlements USING btree (settlement_no);


--
-- Name: idx_ticket_bookings_collection; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ticket_bookings_collection ON public.ticket_bookings USING btree (expected_collection_date) WHERE (payment_status <> 'paid'::text);


--
-- Name: idx_ticket_bookings_invoice; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ticket_bookings_invoice ON public.ticket_bookings USING btree (invoice_no);


--
-- Name: idx_ticket_bookings_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ticket_bookings_status ON public.ticket_bookings USING btree (payment_status, status);


--
-- Name: idx_ticket_bookings_vendor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ticket_bookings_vendor ON public.ticket_bookings USING btree (vendor_id);


--
-- Name: idx_ticket_refunds_booking; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ticket_refunds_booking ON public.ticket_refunds USING btree (ticket_booking_id);


--
-- Name: idx_ticket_refunds_invoice; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ticket_refunds_invoice ON public.ticket_refunds USING btree (invoice_no);


--
-- Name: idx_transactions_booking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_booking_id ON public.transactions USING btree (booking_id);


--
-- Name: idx_transactions_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_date ON public.transactions USING btree (date);


--
-- Name: idx_transactions_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_source_id ON public.transactions USING btree (source_id);


--
-- Name: idx_transactions_source_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_source_type ON public.transactions USING btree (source_type);


--
-- Name: idx_transactions_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_type ON public.transactions USING btree (type);


--
-- Name: idx_visa_applications_invoice; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visa_applications_invoice ON public.visa_applications USING btree (invoice_no);


--
-- Name: idx_visa_applications_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_visa_applications_status ON public.visa_applications USING btree (visa_status, payment_status, status);


--
-- Name: moallem_commission_payments trg_auto_wallet_commission_payments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auto_wallet_commission_payments BEFORE INSERT OR UPDATE ON public.moallem_commission_payments FOR EACH ROW EXECUTE FUNCTION public.auto_assign_wallet();


--
-- Name: supplier_contract_payments trg_auto_wallet_contract_payments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auto_wallet_contract_payments BEFORE INSERT OR UPDATE ON public.supplier_contract_payments FOR EACH ROW EXECUTE FUNCTION public.auto_assign_wallet();


--
-- Name: moallem_payments trg_auto_wallet_moallem_payments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auto_wallet_moallem_payments BEFORE INSERT OR UPDATE ON public.moallem_payments FOR EACH ROW EXECUTE FUNCTION public.auto_assign_wallet();


--
-- Name: payments trg_auto_wallet_payments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auto_wallet_payments BEFORE INSERT OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.auto_assign_wallet();


--
-- Name: supplier_agent_payments trg_auto_wallet_supplier_payments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auto_wallet_supplier_payments BEFORE INSERT OR UPDATE ON public.supplier_agent_payments FOR EACH ROW EXECUTE FUNCTION public.auto_assign_wallet();


--
-- Name: ticket_bookings trg_calc_ticket_booking; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_calc_ticket_booking BEFORE INSERT OR UPDATE ON public.ticket_bookings FOR EACH ROW EXECUTE FUNCTION public.calc_ticket_booking_fields();


--
-- Name: ticket_refunds trg_calc_ticket_refund; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_calc_ticket_refund BEFORE INSERT OR UPDATE ON public.ticket_refunds FOR EACH ROW EXECUTE FUNCTION public.calc_ticket_refund_fields();


--
-- Name: visa_applications trg_calc_visa_application; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_calc_visa_application BEFORE INSERT OR UPDATE ON public.visa_applications FOR EACH ROW EXECUTE FUNCTION public.calc_visa_application_fields();


--
-- Name: bookings trg_calculate_booking_profit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_calculate_booking_profit BEFORE INSERT OR UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.calculate_booking_profit();


--
-- Name: daily_cashbook trg_cashbook_delete_wallet; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cashbook_delete_wallet AFTER DELETE ON public.daily_cashbook FOR EACH ROW EXECUTE FUNCTION public.update_wallet_on_cashbook_delete();


--
-- Name: daily_cashbook trg_cashbook_insert_wallet; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cashbook_insert_wallet AFTER INSERT ON public.daily_cashbook FOR EACH ROW EXECUTE FUNCTION public.update_wallet_on_cashbook_insert();


--
-- Name: daily_cashbook trg_cashbook_update_wallet; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_cashbook_update_wallet AFTER UPDATE ON public.daily_cashbook FOR EACH ROW EXECUTE FUNCTION public.update_wallet_on_cashbook_update();


--
-- Name: packages trg_check_package_expiry; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_check_package_expiry BEFORE INSERT OR UPDATE ON public.packages FOR EACH ROW EXECUTE FUNCTION public.check_package_expiry();


--
-- Name: bookings trg_notify_booking_completed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_notify_booking_completed AFTER UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.notify_booking_completed();


--
-- Name: bookings trg_notify_booking_created; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_notify_booking_created AFTER INSERT ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.notify_booking_created();


--
-- Name: bookings trg_notify_booking_status; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_notify_booking_status AFTER UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.notify_booking_status_updated();


--
-- Name: bookings trg_notify_booking_status_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_notify_booking_status_updated AFTER UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.notify_booking_status_updated();


--
-- Name: moallem_commission_payments trg_notify_commission_payment; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_notify_commission_payment AFTER INSERT ON public.moallem_commission_payments FOR EACH ROW EXECUTE FUNCTION public.notify_commission_payment();


--
-- Name: payments trg_notify_payment_completed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_notify_payment_completed AFTER INSERT OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.notify_payment_completed();


--
-- Name: supplier_agent_payments trg_notify_supplier_payment; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_notify_supplier_payment AFTER INSERT ON public.supplier_agent_payments FOR EACH ROW EXECUTE FUNCTION public.notify_supplier_payment();


--
-- Name: moallem_commission_payments trg_on_commission_payment_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_on_commission_payment_changed AFTER INSERT OR DELETE OR UPDATE ON public.moallem_commission_payments FOR EACH ROW EXECUTE FUNCTION public.on_commission_payment_changed();


--
-- Name: expenses trg_on_expense_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_on_expense_changed AFTER INSERT OR DELETE OR UPDATE ON public.expenses FOR EACH ROW EXECUTE FUNCTION public.on_expense_changed();


--
-- Name: moallem_payments trg_on_moallem_payment_income; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_on_moallem_payment_income AFTER INSERT OR DELETE OR UPDATE ON public.moallem_payments FOR EACH ROW EXECUTE FUNCTION public.on_moallem_payment_income();


--
-- Name: moallem_payments trg_on_moallem_payment_wallet; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_on_moallem_payment_wallet BEFORE INSERT OR DELETE OR UPDATE ON public.moallem_payments FOR EACH ROW EXECUTE FUNCTION public.on_moallem_payment_wallet();


--
-- Name: payments trg_on_payment_completed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_on_payment_completed AFTER INSERT OR DELETE OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.on_payment_completed();


--
-- Name: refunds trg_on_refund_processed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_on_refund_processed BEFORE UPDATE ON public.refunds FOR EACH ROW EXECUTE FUNCTION public.on_refund_processed();


--
-- Name: settlements trg_on_settlement_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_on_settlement_changed AFTER INSERT OR DELETE ON public.settlements FOR EACH ROW EXECUTE FUNCTION public.on_settlement_changed();


--
-- Name: supplier_agent_payments trg_on_supplier_payment_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_on_supplier_payment_changed AFTER INSERT OR DELETE OR UPDATE ON public.supplier_agent_payments FOR EACH ROW EXECUTE FUNCTION public.on_supplier_payment_changed();


--
-- Name: ticket_refunds trg_on_ticket_refund_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_on_ticket_refund_changed AFTER INSERT OR DELETE ON public.ticket_refunds FOR EACH ROW EXECUTE FUNCTION public.on_ticket_refund_changed();


--
-- Name: user_roles trg_protect_admin_role; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_protect_admin_role BEFORE DELETE ON public.user_roles FOR EACH ROW EXECUTE FUNCTION public.protect_admin_role();


--
-- Name: user_roles trg_protect_admin_role_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_protect_admin_role_update BEFORE UPDATE ON public.user_roles FOR EACH ROW EXECUTE FUNCTION public.protect_admin_role_update();


--
-- Name: settlement_items trg_settlement_item_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_settlement_item_changed AFTER INSERT OR DELETE OR UPDATE ON public.settlement_items FOR EACH ROW EXECUTE FUNCTION public.on_settlement_item_changed();


--
-- Name: supplier_contract_payments trg_supplier_contract_payment; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_supplier_contract_payment AFTER INSERT OR DELETE ON public.supplier_contract_payments FOR EACH ROW EXECUTE FUNCTION public.on_supplier_contract_payment();


--
-- Name: moallem_commission_payments trg_update_booking_commission_paid; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_booking_commission_paid AFTER INSERT OR DELETE OR UPDATE ON public.moallem_commission_payments FOR EACH ROW EXECUTE FUNCTION public.update_booking_commission_paid();


--
-- Name: moallem_payments trg_update_booking_moallem_paid; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_booking_moallem_paid AFTER INSERT OR DELETE OR UPDATE ON public.moallem_payments FOR EACH ROW EXECUTE FUNCTION public.update_booking_moallem_paid();


--
-- Name: payments trg_update_booking_paid_amount; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_booking_paid_amount AFTER INSERT OR DELETE OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.update_booking_paid_amount();


--
-- Name: supplier_agent_payments trg_update_booking_supplier_paid; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_booking_supplier_paid AFTER INSERT OR DELETE OR UPDATE ON public.supplier_agent_payments FOR EACH ROW EXECUTE FUNCTION public.update_booking_supplier_paid();


--
-- Name: bookings trg_update_bookings_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_bookings_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: hotels trg_update_hotels_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_hotels_updated_at BEFORE UPDATE ON public.hotels FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: bookings trg_update_moallem_on_booking; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_moallem_on_booking AFTER INSERT OR DELETE OR UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.update_moallem_on_booking();


--
-- Name: moallem_payments trg_update_moallem_on_deposit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_moallem_on_deposit AFTER INSERT OR DELETE OR UPDATE ON public.moallem_payments FOR EACH ROW EXECUTE FUNCTION public.update_moallem_on_deposit();


--
-- Name: moallems trg_update_moallems_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_moallems_updated_at BEFORE UPDATE ON public.moallems FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: supplier_agents trg_update_supplier_agents_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_update_supplier_agents_updated_at BEFORE UPDATE ON public.supplier_agents FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: booking_documents booking_documents_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_documents
    ADD CONSTRAINT booking_documents_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: booking_documents booking_documents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_documents
    ADD CONSTRAINT booking_documents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: booking_members booking_members_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_members
    ADD CONSTRAINT booking_members_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: booking_members booking_members_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_members
    ADD CONSTRAINT booking_members_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.packages(id);


--
-- Name: bookings bookings_installment_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_installment_plan_id_fkey FOREIGN KEY (installment_plan_id) REFERENCES public.installment_plans(id);


--
-- Name: bookings bookings_moallem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_moallem_id_fkey FOREIGN KEY (moallem_id) REFERENCES public.moallems(id) ON DELETE SET NULL;


--
-- Name: bookings bookings_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.packages(id);


--
-- Name: bookings bookings_supplier_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_supplier_agent_id_fkey FOREIGN KEY (supplier_agent_id) REFERENCES public.supplier_agents(id);


--
-- Name: company_settings company_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_settings
    ADD CONSTRAINT company_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: daily_cashbook daily_cashbook_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_cashbook
    ADD CONSTRAINT daily_cashbook_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
-- Name: expenses expenses_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
-- Name: expenses expenses_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.packages(id);


--
-- Name: expenses expenses_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
-- Name: hotel_bookings hotel_bookings_hotel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hotel_bookings
    ADD CONSTRAINT hotel_bookings_hotel_id_fkey FOREIGN KEY (hotel_id) REFERENCES public.hotels(id);


--
-- Name: hotel_bookings hotel_bookings_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hotel_bookings
    ADD CONSTRAINT hotel_bookings_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.hotel_rooms(id);


--
-- Name: hotel_bookings hotel_bookings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hotel_bookings
    ADD CONSTRAINT hotel_bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: hotel_rooms hotel_rooms_hotel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hotel_rooms
    ADD CONSTRAINT hotel_rooms_hotel_id_fkey FOREIGN KEY (hotel_id) REFERENCES public.hotels(id) ON DELETE CASCADE;


--
-- Name: moallem_commission_payments moallem_commission_payments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moallem_commission_payments
    ADD CONSTRAINT moallem_commission_payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
-- Name: moallem_commission_payments moallem_commission_payments_moallem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moallem_commission_payments
    ADD CONSTRAINT moallem_commission_payments_moallem_id_fkey FOREIGN KEY (moallem_id) REFERENCES public.moallems(id) ON DELETE CASCADE;


--
-- Name: moallem_commission_payments moallem_commission_payments_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moallem_commission_payments
    ADD CONSTRAINT moallem_commission_payments_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
-- Name: moallem_items moallem_items_moallem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moallem_items
    ADD CONSTRAINT moallem_items_moallem_id_fkey FOREIGN KEY (moallem_id) REFERENCES public.moallems(id) ON DELETE CASCADE;


--
-- Name: moallem_payments moallem_payments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moallem_payments
    ADD CONSTRAINT moallem_payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
-- Name: moallem_payments moallem_payments_moallem_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moallem_payments
    ADD CONSTRAINT moallem_payments_moallem_id_fkey FOREIGN KEY (moallem_id) REFERENCES public.moallems(id) ON DELETE CASCADE;


--
-- Name: moallem_payments moallem_payments_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moallem_payments
    ADD CONSTRAINT moallem_payments_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
-- Name: notification_logs notification_logs_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_logs
    ADD CONSTRAINT notification_logs_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
-- Name: notification_logs notification_logs_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_logs
    ADD CONSTRAINT notification_logs_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payments(id) ON DELETE SET NULL;


--
-- Name: notification_settings notification_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_settings
    ADD CONSTRAINT notification_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: online_payment_sessions online_payment_sessions_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_payment_sessions
    ADD CONSTRAINT online_payment_sessions_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
-- Name: online_payment_sessions online_payment_sessions_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_payment_sessions
    ADD CONSTRAINT online_payment_sessions_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payments(id);


--
-- Name: payments payments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: payments payments_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
-- Name: refunds refunds_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: refunds refunds_policy_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_policy_id_fkey FOREIGN KEY (policy_id) REFERENCES public.cancellation_policies(id);


--
-- Name: refunds refunds_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refunds
    ADD CONSTRAINT refunds_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
-- Name: settlement_items settlement_items_settlement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settlement_items
    ADD CONSTRAINT settlement_items_settlement_id_fkey FOREIGN KEY (settlement_id) REFERENCES public.settlements(id) ON DELETE CASCADE;


--
-- Name: settlements settlements_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settlements
    ADD CONSTRAINT settlements_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
-- Name: supplier_agent_items supplier_agent_items_supplier_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_agent_items
    ADD CONSTRAINT supplier_agent_items_supplier_agent_id_fkey FOREIGN KEY (supplier_agent_id) REFERENCES public.supplier_agents(id) ON DELETE CASCADE;


--
-- Name: supplier_agent_payments supplier_agent_payments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_agent_payments
    ADD CONSTRAINT supplier_agent_payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
-- Name: supplier_agent_payments supplier_agent_payments_supplier_agent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_agent_payments
    ADD CONSTRAINT supplier_agent_payments_supplier_agent_id_fkey FOREIGN KEY (supplier_agent_id) REFERENCES public.supplier_agents(id);


--
-- Name: supplier_agent_payments supplier_agent_payments_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_agent_payments
    ADD CONSTRAINT supplier_agent_payments_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
-- Name: supplier_contract_payments supplier_contract_payments_contract_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_contract_payments
    ADD CONSTRAINT supplier_contract_payments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.supplier_contracts(id) ON DELETE CASCADE;


--
-- Name: supplier_contract_payments supplier_contract_payments_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_contract_payments
    ADD CONSTRAINT supplier_contract_payments_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier_agents(id) ON DELETE CASCADE;


--
-- Name: supplier_contract_payments supplier_contract_payments_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_contract_payments
    ADD CONSTRAINT supplier_contract_payments_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
-- Name: supplier_contracts supplier_contracts_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_contracts
    ADD CONSTRAINT supplier_contracts_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier_agents(id) ON DELETE CASCADE;


--
-- Name: ticket_bookings ticket_bookings_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_bookings
    ADD CONSTRAINT ticket_bookings_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.supplier_agents(id) ON DELETE SET NULL;


--
-- Name: ticket_refunds ticket_refunds_ticket_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_refunds
    ADD CONSTRAINT ticket_refunds_ticket_booking_id_fkey FOREIGN KEY (ticket_booking_id) REFERENCES public.ticket_bookings(id) ON DELETE SET NULL;


--
-- Name: ticket_refunds ticket_refunds_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_refunds
    ADD CONSTRAINT ticket_refunds_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.supplier_agents(id) ON DELETE SET NULL;


--
-- Name: ticket_refunds ticket_refunds_wallet_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_refunds
    ADD CONSTRAINT ticket_refunds_wallet_account_id_fkey FOREIGN KEY (wallet_account_id) REFERENCES public.accounts(id);


--
-- Name: transactions transactions_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: visa_applications visa_applications_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visa_applications
    ADD CONSTRAINT visa_applications_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.supplier_agents(id) ON DELETE SET NULL;


--
-- Name: profiles Admins can delete profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete profiles" ON public.profiles FOR DELETE USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: user_roles Admins can delete user roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete user roles" ON public.user_roles FOR DELETE USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: audit_logs Admins can insert audit logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert audit logs" ON public.audit_logs FOR INSERT WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: profiles Admins can insert profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert profiles" ON public.profiles FOR INSERT WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: user_roles Admins can insert user roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert user roles" ON public.user_roles FOR INSERT WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: accounts Admins can manage accounts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage accounts" ON public.accounts USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: bookings Admins can manage all bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage all bookings" ON public.bookings USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: booking_documents Admins can manage all documents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage all documents" ON public.booking_documents USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: blog_posts Admins can manage blog posts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage blog posts" ON public.blog_posts USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: booking_members Admins can manage booking members; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage booking members" ON public.booking_members USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: cancellation_policies Admins can manage cancellation policies; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage cancellation policies" ON public.cancellation_policies USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: cms_versions Admins can manage cms versions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage cms versions" ON public.cms_versions USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: moallem_commission_payments Admins can manage commission payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage commission payments" ON public.moallem_commission_payments USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: company_settings Admins can manage company settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage company settings" ON public.company_settings USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: daily_cashbook Admins can manage daily cashbook; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage daily cashbook" ON public.daily_cashbook TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: expenses Admins can manage expenses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage expenses" ON public.expenses USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: financial_summary Admins can manage financial summary; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage financial summary" ON public.financial_summary USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hotel_bookings Admins can manage hotel bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage hotel bookings" ON public.hotel_bookings USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hotels Admins can manage hotels; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage hotels" ON public.hotels USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: moallem_items Admins can manage moallem items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage moallem items" ON public.moallem_items TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: moallem_payments Admins can manage moallem payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage moallem payments" ON public.moallem_payments USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: moallems Admins can manage moallems; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage moallems" ON public.moallems USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: notification_logs Admins can manage notification logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage notification logs" ON public.notification_logs USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: notification_settings Admins can manage notification settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage notification settings" ON public.notification_settings USING ((EXISTS ( SELECT 1
   FROM public.user_roles
  WHERE ((user_roles.user_id = auth.uid()) AND (user_roles.role = 'admin'::public.app_role))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.user_roles
  WHERE ((user_roles.user_id = auth.uid()) AND (user_roles.role = 'admin'::public.app_role)))));


--
-- Name: packages Admins can manage packages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage packages" ON public.packages USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: payments Admins can manage payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage payments" ON public.payments USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: installment_plans Admins can manage plans; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage plans" ON public.installment_plans USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: refunds Admins can manage refunds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage refunds" ON public.refunds USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hotel_rooms Admins can manage rooms; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage rooms" ON public.hotel_rooms USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: site_content Admins can manage site content; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage site content" ON public.site_content USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: supplier_agent_items Admins can manage supplier agent items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage supplier agent items" ON public.supplier_agent_items USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: supplier_agent_payments Admins can manage supplier agent payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage supplier agent payments" ON public.supplier_agent_payments USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: supplier_agents Admins can manage supplier agents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage supplier agents" ON public.supplier_agents USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: supplier_contract_payments Admins can manage supplier contract payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage supplier contract payments" ON public.supplier_contract_payments USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: supplier_contracts Admins can manage supplier contracts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage supplier contracts" ON public.supplier_contracts USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: transactions Admins can manage transactions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can manage transactions" ON public.transactions USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: accounts Admins can read accounts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can read accounts" ON public.accounts FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: financial_summary Admins can read financial summary; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can read financial summary" ON public.financial_summary FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: profiles Admins can update all profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update all profiles" ON public.profiles FOR UPDATE USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: user_roles Admins can update user roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update user roles" ON public.user_roles FOR UPDATE USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: profiles Admins can view all profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can view all profiles" ON public.profiles FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: user_roles Admins can view all user roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can view all user roles" ON public.user_roles FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: audit_logs Admins can view audit logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can view audit logs" ON public.audit_logs FOR SELECT USING (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: online_payment_sessions Admins manage online payment sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage online payment sessions" ON public.online_payment_sessions TO authenticated USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: settlement_items Admins manage settlement items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage settlement items" ON public.settlement_items USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: settlements Admins manage settlements; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage settlements" ON public.settlements USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: admin_2fa Admins manage their own 2FA settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage their own 2FA settings" ON public.admin_2fa USING ((public.has_role(auth.uid(), 'admin'::public.app_role) AND (auth.uid() = user_id))) WITH CHECK ((public.has_role(auth.uid(), 'admin'::public.app_role) AND (auth.uid() = user_id)));


--
-- Name: ticket_bookings Admins manage ticket bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage ticket bookings" ON public.ticket_bookings USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: ticket_refunds Admins manage ticket refunds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage ticket refunds" ON public.ticket_refunds USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: visa_applications Admins manage visa applications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins manage visa applications" ON public.visa_applications USING (public.has_role(auth.uid(), 'admin'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'admin'::public.app_role));


--
-- Name: hotels Anyone can view active hotels; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view active hotels" ON public.hotels FOR SELECT USING ((is_active = true));


--
-- Name: packages Anyone can view active packages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view active packages" ON public.packages FOR SELECT USING ((is_active = true));


--
-- Name: installment_plans Anyone can view active plans; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view active plans" ON public.installment_plans FOR SELECT USING ((is_active = true));


--
-- Name: cancellation_policies Anyone can view active policies; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view active policies" ON public.cancellation_policies FOR SELECT USING ((is_active = true));


--
-- Name: hotel_rooms Anyone can view available rooms; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view available rooms" ON public.hotel_rooms FOR SELECT USING ((is_available = true));


--
-- Name: blog_posts Anyone can view published posts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view published posts" ON public.blog_posts FOR SELECT USING ((status = 'published'::text));


--
-- Name: site_content Anyone can view site content; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view site content" ON public.site_content FOR SELECT USING (true);


--
-- Name: company_settings Authenticated users can view company settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can view company settings" ON public.company_settings FOR SELECT USING ((auth.uid() IS NOT NULL));


--
-- Name: notification_settings Authenticated users can view notification settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can view notification settings" ON public.notification_settings FOR SELECT USING ((auth.uid() IS NOT NULL));


--
-- Name: moallem_commission_payments Staff can view commission payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view commission payments" ON public.moallem_commission_payments FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: daily_cashbook Staff can view daily cashbook; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view daily cashbook" ON public.daily_cashbook FOR SELECT TO authenticated USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: moallem_items Staff can view moallem items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view moallem items" ON public.moallem_items FOR SELECT TO authenticated USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: moallem_payments Staff can view moallem payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view moallem payments" ON public.moallem_payments FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: moallems Staff can view moallems; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view moallems" ON public.moallems FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: refunds Staff can view refunds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view refunds" ON public.refunds FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: supplier_agent_items Staff can view supplier agent items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view supplier agent items" ON public.supplier_agent_items FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: supplier_agent_payments Staff can view supplier agent payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view supplier agent payments" ON public.supplier_agent_payments FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: supplier_agents Staff can view supplier agents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view supplier agents" ON public.supplier_agents FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: supplier_contract_payments Staff can view supplier contract payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view supplier contract payments" ON public.supplier_contract_payments FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: supplier_contracts Staff can view supplier contracts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff can view supplier contracts" ON public.supplier_contracts FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: settlement_items Staff view settlement items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff view settlement items" ON public.settlement_items FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: settlements Staff view settlements; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff view settlements" ON public.settlements FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: ticket_bookings Staff view ticket bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff view ticket bookings" ON public.ticket_bookings FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: ticket_refunds Staff view ticket refunds; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff view ticket refunds" ON public.ticket_refunds FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: visa_applications Staff view visa applications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Staff view visa applications" ON public.visa_applications FOR SELECT USING ((public.has_role(auth.uid(), 'admin'::public.app_role) OR public.has_role(auth.uid(), 'manager'::public.app_role) OR public.has_role(auth.uid(), 'accountant'::public.app_role) OR public.has_role(auth.uid(), 'staff'::public.app_role) OR public.has_role(auth.uid(), 'viewer'::public.app_role)));


--
-- Name: bookings Users can create bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create bookings" ON public.bookings FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));


--
-- Name: hotel_bookings Users can create hotel bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create hotel bookings" ON public.hotel_bookings FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: booking_documents Users can delete own documents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete own documents" ON public.booking_documents FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: profiles Users can insert own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: profiles Users can update own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: booking_documents Users can upload own documents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can upload own documents" ON public.booking_documents FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: booking_members Users can view own booking members; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own booking members" ON public.booking_members FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.bookings
  WHERE ((bookings.id = booking_members.booking_id) AND (bookings.user_id = auth.uid())))));


--
-- Name: bookings Users can view own bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own bookings" ON public.bookings FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: booking_documents Users can view own documents; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own documents" ON public.booking_documents FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: hotel_bookings Users can view own hotel bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own hotel bookings" ON public.hotel_bookings FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: notification_logs Users can view own notification logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own notification logs" ON public.notification_logs FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: payments Users can view own payments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own payments" ON public.payments FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: profiles Users can view own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_roles Users can view own roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own roles" ON public.user_roles FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: transactions Users can view own transactions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own transactions" ON public.transactions FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: online_payment_sessions Users view own payment sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users view own payment sessions" ON public.online_payment_sessions FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: accounts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

--
-- Name: admin_2fa; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_2fa ENABLE ROW LEVEL SECURITY;

--
-- Name: admin_2fa_codes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_2fa_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: blog_posts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;

--
-- Name: booking_documents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.booking_documents ENABLE ROW LEVEL SECURITY;

--
-- Name: booking_members; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.booking_members ENABLE ROW LEVEL SECURITY;

--
-- Name: bookings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

--
-- Name: cancellation_policies; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.cancellation_policies ENABLE ROW LEVEL SECURITY;

--
-- Name: cms_versions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.cms_versions ENABLE ROW LEVEL SECURITY;

--
-- Name: company_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: daily_cashbook; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.daily_cashbook ENABLE ROW LEVEL SECURITY;

--
-- Name: expenses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

--
-- Name: financial_summary; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.financial_summary ENABLE ROW LEVEL SECURITY;

--
-- Name: hotel_bookings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hotel_bookings ENABLE ROW LEVEL SECURITY;

--
-- Name: hotel_rooms; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hotel_rooms ENABLE ROW LEVEL SECURITY;

--
-- Name: hotels; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hotels ENABLE ROW LEVEL SECURITY;

--
-- Name: installment_plans; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.installment_plans ENABLE ROW LEVEL SECURITY;

--
-- Name: moallem_commission_payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.moallem_commission_payments ENABLE ROW LEVEL SECURITY;

--
-- Name: moallem_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.moallem_items ENABLE ROW LEVEL SECURITY;

--
-- Name: moallem_payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.moallem_payments ENABLE ROW LEVEL SECURITY;

--
-- Name: moallems; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.moallems ENABLE ROW LEVEL SECURITY;

--
-- Name: notification_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: notification_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: online_payment_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.online_payment_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: otp_codes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: packages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;

--
-- Name: payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: refunds; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;

--
-- Name: settlement_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.settlement_items ENABLE ROW LEVEL SECURITY;

--
-- Name: settlements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;

--
-- Name: site_content; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.site_content ENABLE ROW LEVEL SECURITY;

--
-- Name: supplier_agent_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supplier_agent_items ENABLE ROW LEVEL SECURITY;

--
-- Name: supplier_agent_payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supplier_agent_payments ENABLE ROW LEVEL SECURITY;

--
-- Name: supplier_agents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supplier_agents ENABLE ROW LEVEL SECURITY;

--
-- Name: supplier_contract_payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supplier_contract_payments ENABLE ROW LEVEL SECURITY;

--
-- Name: supplier_contracts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supplier_contracts ENABLE ROW LEVEL SECURITY;

--
-- Name: ticket_bookings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ticket_bookings ENABLE ROW LEVEL SECURITY;

--
-- Name: ticket_refunds; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ticket_refunds ENABLE ROW LEVEL SECURITY;

--
-- Name: transactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: user_roles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

--
-- Name: visa_applications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.visa_applications ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict 5G7GNXracf6d8n9Twva9IYLtK1zOF4gVUR6IxlhPr5LlmK0e56Wyhfchz45aWAS

