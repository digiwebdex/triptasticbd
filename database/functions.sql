-- Generated from Supabase pg_dump
-- Apply order: schema.sql -> functions.sql -> data.sql -> indexes.sql -> constraints.sql

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
CREATE FUNCTION public.gen_refund_invoice_no() RETURNS text
    LANGUAGE sql
    AS $$
  SELECT 'RFN' || to_char(CURRENT_DATE, 'YYYY') || lpad(nextval('public.refund_invoice_seq')::text, 5, '0')
$$;


--
CREATE FUNCTION public.gen_settlement_no() RETURNS text
    LANGUAGE sql
    AS $$
  SELECT 'STM' || to_char(CURRENT_DATE, 'YYYY') || lpad(nextval('public.settlement_no_seq')::text, 7, '0')
$$;


--
CREATE FUNCTION public.gen_ticket_invoice_no() RETURNS text
    LANGUAGE sql
    AS $$
  SELECT 'TKT' || to_char(CURRENT_DATE, 'YYYY') || lpad(nextval('public.ticket_invoice_seq')::text, 5, '0')
$$;


--
CREATE FUNCTION public.gen_visa_invoice_no() RETURNS text
    LANGUAGE sql
    AS $$
  SELECT 'VS' || to_char(CURRENT_DATE, 'YYYY') || lpad(nextval('public.visa_invoice_seq')::text, 5, '0')
$$;


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
CREATE FUNCTION public.has_role(_user_id uuid, _role public.app_role) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;


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


CREATE TRIGGER trg_auto_wallet_commission_payments BEFORE INSERT OR UPDATE ON public.moallem_commission_payments FOR EACH ROW EXECUTE FUNCTION public.auto_assign_wallet();


--
CREATE TRIGGER trg_auto_wallet_contract_payments BEFORE INSERT OR UPDATE ON public.supplier_contract_payments FOR EACH ROW EXECUTE FUNCTION public.auto_assign_wallet();


--
CREATE TRIGGER trg_auto_wallet_moallem_payments BEFORE INSERT OR UPDATE ON public.moallem_payments FOR EACH ROW EXECUTE FUNCTION public.auto_assign_wallet();


--
CREATE TRIGGER trg_auto_wallet_payments BEFORE INSERT OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.auto_assign_wallet();


--
CREATE TRIGGER trg_auto_wallet_supplier_payments BEFORE INSERT OR UPDATE ON public.supplier_agent_payments FOR EACH ROW EXECUTE FUNCTION public.auto_assign_wallet();


--
CREATE TRIGGER trg_calc_ticket_booking BEFORE INSERT OR UPDATE ON public.ticket_bookings FOR EACH ROW EXECUTE FUNCTION public.calc_ticket_booking_fields();


--
CREATE TRIGGER trg_calc_ticket_refund BEFORE INSERT OR UPDATE ON public.ticket_refunds FOR EACH ROW EXECUTE FUNCTION public.calc_ticket_refund_fields();


--
CREATE TRIGGER trg_calc_visa_application BEFORE INSERT OR UPDATE ON public.visa_applications FOR EACH ROW EXECUTE FUNCTION public.calc_visa_application_fields();


--
CREATE TRIGGER trg_calculate_booking_profit BEFORE INSERT OR UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.calculate_booking_profit();


--
CREATE TRIGGER trg_cashbook_delete_wallet AFTER DELETE ON public.daily_cashbook FOR EACH ROW EXECUTE FUNCTION public.update_wallet_on_cashbook_delete();


--
CREATE TRIGGER trg_cashbook_insert_wallet AFTER INSERT ON public.daily_cashbook FOR EACH ROW EXECUTE FUNCTION public.update_wallet_on_cashbook_insert();


--
CREATE TRIGGER trg_cashbook_update_wallet AFTER UPDATE ON public.daily_cashbook FOR EACH ROW EXECUTE FUNCTION public.update_wallet_on_cashbook_update();


--
CREATE TRIGGER trg_check_package_expiry BEFORE INSERT OR UPDATE ON public.packages FOR EACH ROW EXECUTE FUNCTION public.check_package_expiry();


--
CREATE TRIGGER trg_notify_booking_completed AFTER UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.notify_booking_completed();


--
CREATE TRIGGER trg_notify_booking_created AFTER INSERT ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.notify_booking_created();


--
CREATE TRIGGER trg_notify_booking_status AFTER UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.notify_booking_status_updated();


--
CREATE TRIGGER trg_notify_booking_status_updated AFTER UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.notify_booking_status_updated();


--
CREATE TRIGGER trg_notify_commission_payment AFTER INSERT ON public.moallem_commission_payments FOR EACH ROW EXECUTE FUNCTION public.notify_commission_payment();


--
CREATE TRIGGER trg_notify_payment_completed AFTER INSERT OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.notify_payment_completed();


--
CREATE TRIGGER trg_notify_supplier_payment AFTER INSERT ON public.supplier_agent_payments FOR EACH ROW EXECUTE FUNCTION public.notify_supplier_payment();


--
CREATE TRIGGER trg_on_commission_payment_changed AFTER INSERT OR DELETE OR UPDATE ON public.moallem_commission_payments FOR EACH ROW EXECUTE FUNCTION public.on_commission_payment_changed();


--
CREATE TRIGGER trg_on_expense_changed AFTER INSERT OR DELETE OR UPDATE ON public.expenses FOR EACH ROW EXECUTE FUNCTION public.on_expense_changed();


--
CREATE TRIGGER trg_on_moallem_payment_income AFTER INSERT OR DELETE OR UPDATE ON public.moallem_payments FOR EACH ROW EXECUTE FUNCTION public.on_moallem_payment_income();


--
CREATE TRIGGER trg_on_moallem_payment_wallet BEFORE INSERT OR DELETE OR UPDATE ON public.moallem_payments FOR EACH ROW EXECUTE FUNCTION public.on_moallem_payment_wallet();


--
CREATE TRIGGER trg_on_payment_completed AFTER INSERT OR DELETE OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.on_payment_completed();


--
CREATE TRIGGER trg_on_refund_processed BEFORE UPDATE ON public.refunds FOR EACH ROW EXECUTE FUNCTION public.on_refund_processed();


--
CREATE TRIGGER trg_on_settlement_changed AFTER INSERT OR DELETE ON public.settlements FOR EACH ROW EXECUTE FUNCTION public.on_settlement_changed();


--
CREATE TRIGGER trg_on_supplier_payment_changed AFTER INSERT OR DELETE OR UPDATE ON public.supplier_agent_payments FOR EACH ROW EXECUTE FUNCTION public.on_supplier_payment_changed();


--
CREATE TRIGGER trg_on_ticket_refund_changed AFTER INSERT OR DELETE ON public.ticket_refunds FOR EACH ROW EXECUTE FUNCTION public.on_ticket_refund_changed();


--
CREATE TRIGGER trg_protect_admin_role BEFORE DELETE ON public.user_roles FOR EACH ROW EXECUTE FUNCTION public.protect_admin_role();


--
CREATE TRIGGER trg_protect_admin_role_update BEFORE UPDATE ON public.user_roles FOR EACH ROW EXECUTE FUNCTION public.protect_admin_role_update();


--
CREATE TRIGGER trg_settlement_item_changed AFTER INSERT OR DELETE OR UPDATE ON public.settlement_items FOR EACH ROW EXECUTE FUNCTION public.on_settlement_item_changed();


--
CREATE TRIGGER trg_supplier_contract_payment AFTER INSERT OR DELETE ON public.supplier_contract_payments FOR EACH ROW EXECUTE FUNCTION public.on_supplier_contract_payment();


--
CREATE TRIGGER trg_update_booking_commission_paid AFTER INSERT OR DELETE OR UPDATE ON public.moallem_commission_payments FOR EACH ROW EXECUTE FUNCTION public.update_booking_commission_paid();


--
CREATE TRIGGER trg_update_booking_moallem_paid AFTER INSERT OR DELETE OR UPDATE ON public.moallem_payments FOR EACH ROW EXECUTE FUNCTION public.update_booking_moallem_paid();


--
CREATE TRIGGER trg_update_booking_paid_amount AFTER INSERT OR DELETE OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.update_booking_paid_amount();


--
CREATE TRIGGER trg_update_booking_supplier_paid AFTER INSERT OR DELETE OR UPDATE ON public.supplier_agent_payments FOR EACH ROW EXECUTE FUNCTION public.update_booking_supplier_paid();


--
CREATE TRIGGER trg_update_bookings_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
CREATE TRIGGER trg_update_hotels_updated_at BEFORE UPDATE ON public.hotels FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
CREATE TRIGGER trg_update_moallem_on_booking AFTER INSERT OR DELETE OR UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.update_moallem_on_booking();


--
CREATE TRIGGER trg_update_moallem_on_deposit AFTER INSERT OR DELETE OR UPDATE ON public.moallem_payments FOR EACH ROW EXECUTE FUNCTION public.update_moallem_on_deposit();


--
CREATE TRIGGER trg_update_moallems_updated_at BEFORE UPDATE ON public.moallems FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
CREATE TRIGGER trg_update_supplier_agents_updated_at BEFORE UPDATE ON public.supplier_agents FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
