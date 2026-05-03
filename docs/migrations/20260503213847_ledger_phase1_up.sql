-- =====================================================================
-- Migration:   20260503213847_ledger_phase1_up.sql
-- Name:        Phase 1 — Double-Entry Ledger Foundation (parallel, additive)
-- Version:     v1.1 — added inactive/empty/negative guards in post_journal_entry();
--                     RPC now returns (entry_id uuid, entry_number text)
-- Date:        2026-05-03
-- Author:      TripTastic ERP
-- Plan:        docs/LEDGER_MIGRATION_PLAN.md
-- Rollback:    docs/migrations/ledger_phase1_down.sql
-- Dependencies:
--   - public.has_role(uuid, public.app_role)   (existing)
--   - public.app_role enum with 'admin','accountant','viewer'
--   - public.company_settings(setting_key text, setting_value jsonb)
--   - auth.users
-- Safety:
--   - Wrapped in BEGIN/COMMIT — atomic. Partial failure rolls back fully.
--   - Does NOT modify any existing table, trigger, function, or wallet.
--   - All seed inserts are idempotent on UNIQUE(code).
-- =====================================================================

BEGIN;

-- =========================================================
-- 1. CHART OF ACCOUNTS
-- =========================================================
CREATE TABLE public.ledger_accounts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            VARCHAR(10) UNIQUE NOT NULL
                    CHECK (code ~ '^[0-9]{4}(-[A-Z]{3})?$'),
  name            VARCHAR(255) NOT NULL,
  type            VARCHAR(20)  NOT NULL
                    CHECK (type IN ('ASSET','LIABILITY','EQUITY','REVENUE','COGS','EXPENSE')),
  parent_id       UUID REFERENCES public.ledger_accounts(id),
  normal_balance  VARCHAR(6)   NOT NULL CHECK (normal_balance IN ('DEBIT','CREDIT')),
  currency        CHAR(3)      NOT NULL DEFAULT 'BDT',
  legacy_wallet_id UUID,  -- optional link to legacy public.accounts.id (informational only)
  is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_ledger_accounts_parent ON public.ledger_accounts(parent_id);
CREATE INDEX idx_ledger_accounts_type   ON public.ledger_accounts(type);

-- Seed the 33-account COA
INSERT INTO public.ledger_accounts (code, name, type, normal_balance) VALUES
  ('1100','Cash on Hand','ASSET','DEBIT'),
  ('1200','Bank Account','ASSET','DEBIT'),
  ('1210','bKash Wallet','ASSET','DEBIT'),
  ('1220','Nagad Wallet','ASSET','DEBIT'),
  ('1300','Accounts Receivable - Customers','ASSET','DEBIT'),
  ('1310','Moallem Advances Receivable','ASSET','DEBIT'),
  ('1400','Prepaid Expenses','ASSET','DEBIT'),
  ('2100','Accounts Payable - Suppliers','LIABILITY','CREDIT'),
  ('2200','Customer Deposits (Unearned Revenue)','LIABILITY','CREDIT'),
  ('2300','Moallem Commission Payable','LIABILITY','CREDIT'),
  ('2400','Refunds Payable','LIABILITY','CREDIT'),
  ('2500','SSLCommerz Gateway Liability','LIABILITY','CREDIT'),
  ('3100','Owner''s Capital','EQUITY','CREDIT'),
  ('3200','Retained Earnings','EQUITY','CREDIT'),
  ('4100','Hajj Package Revenue','REVENUE','CREDIT'),
  ('4200','Umrah Package Revenue','REVENUE','CREDIT'),
  ('4300','Tour Revenue','REVENUE','CREDIT'),
  ('4400','Air Ticket Revenue','REVENUE','CREDIT'),
  ('4500','Visa Service Revenue','REVENUE','CREDIT'),
  ('4600','Air Ambulance Revenue','REVENUE','CREDIT'),
  ('5100','Hajj/Umrah Supplier Cost','COGS','DEBIT'),
  ('5200','Hotel Cost','COGS','DEBIT'),
  ('5300','Air Ticket Cost','COGS','DEBIT'),
  ('5400','Visa Processing Cost','COGS','DEBIT'),
  ('5500','Moallem Commission Expense','COGS','DEBIT'),
  ('6100','Office Rent','EXPENSE','DEBIT'),
  ('6200','Salaries','EXPENSE','DEBIT'),
  ('6300','Marketing','EXPENSE','DEBIT'),
  ('6400','Utilities','EXPENSE','DEBIT'),
  ('6500','SMS/Communication','EXPENSE','DEBIT'),
  ('6600','Bank/Gateway Fees','EXPENSE','DEBIT'),
  ('6700','Refund Losses','EXPENSE','DEBIT')
ON CONFLICT (code) DO NOTHING;

-- =========================================================
-- 2. ACCOUNTING PERIODS
-- =========================================================
CREATE TABLE public.accounting_periods (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  period_year  INT NOT NULL CHECK (period_year BETWEEN 2020 AND 2100),
  period_month INT NOT NULL CHECK (period_month BETWEEN 1 AND 12),
  status       VARCHAR(10) NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed')),
  closed_at    TIMESTAMPTZ,
  closed_by    UUID REFERENCES auth.users(id),
  trial_balance_snapshot JSONB,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (period_year, period_month)
);

-- =========================================================
-- 3. JOURNAL ENTRIES + LINES
-- =========================================================
CREATE SEQUENCE public.journal_entry_seq;

CREATE TABLE public.journal_entries (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_number         VARCHAR(20) UNIQUE NOT NULL
                         DEFAULT ('JE-' || to_char(CURRENT_DATE, 'YYYY') || '-' ||
                                  lpad(nextval('public.journal_entry_seq')::text, 6, '0')),
  entry_date           DATE NOT NULL,
  description          TEXT NOT NULL,
  reference_type       VARCHAR(50),  -- booking|payment|refund|expense|opening_balance|manual
  reference_id         UUID,
  posted_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
  posted_by            UUID         NOT NULL REFERENCES auth.users(id),
  is_reversed          BOOLEAN      NOT NULL DEFAULT FALSE,
  reversed_by_entry_id UUID         REFERENCES public.journal_entries(id),
  period_locked        BOOLEAN      NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_journal_entries_date     ON public.journal_entries(entry_date);
CREATE INDEX idx_journal_entries_ref      ON public.journal_entries(reference_type, reference_id);

CREATE TABLE public.journal_lines (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_entry_id  UUID NOT NULL REFERENCES public.journal_entries(id) ON DELETE RESTRICT,
  account_id        UUID NOT NULL REFERENCES public.ledger_accounts(id),
  debit_amount      NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (debit_amount  >= 0),
  credit_amount     NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (credit_amount >= 0),
  currency          CHAR(3)       NOT NULL DEFAULT 'BDT',
  exchange_rate     NUMERIC(10,6) NOT NULL DEFAULT 1,
  description       TEXT,
  CHECK (
    (debit_amount  > 0 AND credit_amount = 0) OR
    (credit_amount > 0 AND debit_amount  = 0)
  )
);
CREATE INDEX idx_journal_lines_entry   ON public.journal_lines(journal_entry_id);
CREATE INDEX idx_journal_lines_account ON public.journal_lines(account_id);

-- =========================================================
-- 4. OPENING BALANCE ENTRY (one-time bridge)
-- =========================================================
CREATE TABLE public.opening_balance_entries (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ledger_start_date   DATE NOT NULL,
  journal_entry_id    UUID NOT NULL UNIQUE REFERENCES public.journal_entries(id),
  verified_by         UUID NOT NULL REFERENCES auth.users(id),
  verification_notes  TEXT,
  breakdown           JSONB NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Only ONE opening balance entry can ever exist
CREATE UNIQUE INDEX one_opening_balance ON public.opening_balance_entries ((true));

-- =========================================================
-- 5. TRIGGER FUNCTIONS (SECURITY DEFINER, pinned search_path)
-- =========================================================

-- 5.1 Enforce DR = CR per journal entry
CREATE OR REPLACE FUNCTION public.enforce_journal_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_entry_id    UUID;
  v_total_debit NUMERIC;
  v_total_credit NUMERIC;
BEGIN
  v_entry_id := COALESCE(NEW.journal_entry_id, OLD.journal_entry_id);

  SELECT COALESCE(SUM(debit_amount), 0), COALESCE(SUM(credit_amount), 0)
    INTO v_total_debit, v_total_credit
    FROM public.journal_lines
   WHERE journal_entry_id = v_entry_id;

  IF v_total_debit <> v_total_credit THEN
    RAISE EXCEPTION 'Journal entry % is unbalanced: DR=% CR=%',
      v_entry_id, v_total_debit, v_total_credit;
  END IF;
  RETURN NULL;
END;
$$;

-- 5.2 Block edits to posted journal entries (allow only is_reversed flip)
CREATE OR REPLACE FUNCTION public.block_journal_edits()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF OLD.posted_at IS NOT NULL THEN
    -- Only allow flipping is_reversed/reversed_by_entry_id; everything else frozen
    IF (NEW.entry_date     IS DISTINCT FROM OLD.entry_date)
    OR (NEW.description    IS DISTINCT FROM OLD.description)
    OR (NEW.reference_type IS DISTINCT FROM OLD.reference_type)
    OR (NEW.reference_id   IS DISTINCT FROM OLD.reference_id)
    OR (NEW.posted_by      IS DISTINCT FROM OLD.posted_by)
    OR (NEW.entry_number   IS DISTINCT FROM OLD.entry_number)
    OR (NEW.posted_at      IS DISTINCT FROM OLD.posted_at) THEN
      RAISE EXCEPTION 'Cannot modify posted journal entry %. Create a reversal entry instead.', OLD.id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- 5.3 Block any UPDATE/DELETE on journal_lines once parent is posted
CREATE OR REPLACE FUNCTION public.block_journal_line_edits()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_posted_at TIMESTAMPTZ;
  v_entry_id  UUID;
BEGIN
  v_entry_id := COALESCE(NEW.journal_entry_id, OLD.journal_entry_id);
  SELECT posted_at INTO v_posted_at FROM public.journal_entries WHERE id = v_entry_id;
  IF v_posted_at IS NOT NULL AND TG_OP IN ('UPDATE','DELETE') THEN
    RAISE EXCEPTION 'Cannot % journal_lines for posted entry %. Use a reversal entry.', TG_OP, v_entry_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- 5.4 Enforce ledger_start_date and period lock
CREATE OR REPLACE FUNCTION public.enforce_ledger_start_date()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_start_date DATE;
  v_period_status TEXT;
BEGIN
  SELECT (setting_value->>'value')::date INTO v_start_date
    FROM public.company_settings
   WHERE setting_key = 'ledger_start_date';

  IF v_start_date IS NULL THEN
    RAISE EXCEPTION 'ledger_start_date is not set. Configure it in Settings → Ledger before posting entries.';
  END IF;

  IF NEW.entry_date < v_start_date THEN
    RAISE EXCEPTION 'entry_date % is before ledger_start_date %. Backdated entries are not allowed.',
      NEW.entry_date, v_start_date;
  END IF;

  -- Period lock check
  SELECT status INTO v_period_status
    FROM public.accounting_periods
   WHERE period_year  = EXTRACT(YEAR  FROM NEW.entry_date)::INT
     AND period_month = EXTRACT(MONTH FROM NEW.entry_date)::INT;

  IF v_period_status = 'closed' THEN
    RAISE EXCEPTION 'Period %-% is closed. Cannot post entries to a closed period.',
      EXTRACT(YEAR FROM NEW.entry_date)::INT, EXTRACT(MONTH FROM NEW.entry_date)::INT;
  END IF;

  RETURN NEW;
END;
$$;

-- 5.5 Lock ledger_start_date once first journal entry exists
CREATE OR REPLACE FUNCTION public.lock_ledger_start_date()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.setting_key = 'ledger_start_date'
     AND (TG_OP = 'UPDATE' OR TG_OP = 'INSERT')
     AND OLD.setting_value IS DISTINCT FROM NEW.setting_value
     AND EXISTS (SELECT 1 FROM public.journal_entries LIMIT 1) THEN
    RAISE EXCEPTION 'ledger_start_date is immutable: journal entries already exist.';
  END IF;
  RETURN NEW;
END;
$$;

-- =========================================================
-- 6. TRIGGERS
-- =========================================================
CREATE CONSTRAINT TRIGGER trg_enforce_journal_balance
  AFTER INSERT OR UPDATE OR DELETE ON public.journal_lines
  DEFERRABLE INITIALLY IMMEDIATE
  FOR EACH ROW EXECUTE FUNCTION public.enforce_journal_balance();

CREATE TRIGGER trg_block_journal_line_edits
  BEFORE UPDATE OR DELETE ON public.journal_lines
  FOR EACH ROW EXECUTE FUNCTION public.block_journal_line_edits();

CREATE TRIGGER trg_block_journal_edits
  BEFORE UPDATE ON public.journal_entries
  FOR EACH ROW EXECUTE FUNCTION public.block_journal_edits();

CREATE TRIGGER trg_enforce_ledger_start_date
  BEFORE INSERT ON public.journal_entries
  FOR EACH ROW EXECUTE FUNCTION public.enforce_ledger_start_date();

CREATE TRIGGER trg_lock_ledger_start_date
  BEFORE UPDATE ON public.company_settings
  FOR EACH ROW EXECUTE FUNCTION public.lock_ledger_start_date();

-- =========================================================
-- 7. POST_JOURNAL_ENTRY HELPER (concurrent-safe writer)
-- =========================================================
CREATE OR REPLACE FUNCTION public.post_journal_entry(
  p_description    TEXT,
  p_entry_date     DATE,
  p_reference_type VARCHAR,
  p_reference_id   UUID,
  p_lines          JSONB    -- [{account_code, debit, credit, description?}, ...]
) RETURNS TABLE (entry_id UUID, entry_number TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_entry_id     UUID;
  v_entry_number TEXT;
  v_line         JSONB;
  v_acc_id       UUID;
  v_debit        NUMERIC;
  v_credit       NUMERIC;
  i              INT;
  v_len          INT;
BEGIN
  -- 1) RBAC
  IF NOT (public.has_role(auth.uid(), 'admin'::public.app_role)
       OR public.has_role(auth.uid(), 'accountant'::public.app_role)) THEN
    RAISE EXCEPTION 'Only admin or accountant can post journal entries.';
  END IF;

  -- 2) Empty-lines guard (BEFORE any INSERT)
  IF p_lines IS NULL OR jsonb_typeof(p_lines) <> 'array' OR jsonb_array_length(p_lines) = 0 THEN
    RAISE EXCEPTION 'Journal entry must have at least one line.';
  END IF;

  -- 3) Pre-validate every line BEFORE any INSERT happens
  --    (inactive account + negative amounts). This guarantees no partial entry.
  v_len := jsonb_array_length(p_lines);
  FOR i IN 0 .. v_len - 1 LOOP
    v_line   := p_lines -> i;
    v_debit  := COALESCE((v_line->>'debit')::numeric,  0);
    v_credit := COALESCE((v_line->>'credit')::numeric, 0);

    IF v_debit < 0 OR v_credit < 0 THEN
      RAISE EXCEPTION 'Debit and credit amounts must be non-negative (line %): debit=%, credit=%',
                      i + 1, v_debit, v_credit;
    END IF;

    PERFORM 1 FROM public.ledger_accounts
      WHERE code = v_line->>'account_code' AND is_active = TRUE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Unknown or inactive account code: %', v_line->>'account_code';
    END IF;
  END LOOP;

  -- 4) All guards passed — create header
  INSERT INTO public.journal_entries (entry_date, description, reference_type, reference_id, posted_by)
  VALUES (p_entry_date, p_description, p_reference_type, p_reference_id, auth.uid())
  RETURNING id, journal_entries.entry_number
  INTO v_entry_id, v_entry_number;

  -- Row-level lock on the parent entry for concurrent-write safety
  PERFORM 1 FROM public.journal_entries WHERE id = v_entry_id FOR UPDATE;

  -- 5) Insert lines (re-resolve account_id; validation already passed)
  FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
  LOOP
    SELECT id INTO v_acc_id FROM public.ledger_accounts
      WHERE code = v_line->>'account_code' AND is_active = TRUE;

    INSERT INTO public.journal_lines
      (journal_entry_id, account_id, debit_amount, credit_amount, description)
    VALUES (
      v_entry_id, v_acc_id,
      COALESCE((v_line->>'debit')::numeric, 0),
      COALESCE((v_line->>'credit')::numeric, 0),
      v_line->>'description'
    );
  END LOOP;

  -- enforce_journal_balance (CONSTRAINT TRIGGER) fires at COMMIT and
  -- guarantees SUM(debit) = SUM(credit) across the whole entry.

  entry_id     := v_entry_id;
  entry_number := v_entry_number;
  RETURN NEXT;
END;
$$;

-- =========================================================
-- 8. VIEWS (security_invoker = true so they respect caller's RLS)
-- =========================================================
CREATE VIEW public.ledger_account_balances WITH (security_invoker = true) AS
SELECT
  a.id, a.code, a.name, a.type, a.normal_balance, a.currency,
  COALESCE(SUM(jl.debit_amount), 0)  AS total_debits,
  COALESCE(SUM(jl.credit_amount), 0) AS total_credits,
  CASE WHEN a.normal_balance = 'DEBIT'
    THEN COALESCE(SUM(jl.debit_amount), 0) - COALESCE(SUM(jl.credit_amount), 0)
    ELSE COALESCE(SUM(jl.credit_amount), 0) - COALESCE(SUM(jl.debit_amount), 0)
  END AS balance
FROM public.ledger_accounts a
LEFT JOIN public.journal_lines   jl ON jl.account_id = a.id
LEFT JOIN public.journal_entries je ON je.id = jl.journal_entry_id AND je.is_reversed = FALSE
GROUP BY a.id, a.code, a.name, a.type, a.normal_balance, a.currency;

CREATE VIEW public.ledger_wallet_balances WITH (security_invoker = true) AS
SELECT code, name, balance
  FROM public.ledger_account_balances
 WHERE code IN ('1100','1200','1210','1220');

CREATE VIEW public.ledger_profit_loss WITH (security_invoker = true) AS
SELECT
  COALESCE((SELECT SUM(balance) FROM public.ledger_account_balances WHERE type='REVENUE'), 0) AS revenue,
  COALESCE((SELECT SUM(balance) FROM public.ledger_account_balances WHERE type='COGS'),    0) AS cogs,
  COALESCE((SELECT SUM(balance) FROM public.ledger_account_balances WHERE type='EXPENSE'), 0) AS expenses,
  COALESCE((SELECT SUM(balance) FROM public.ledger_account_balances WHERE type='REVENUE'), 0)
   - COALESCE((SELECT SUM(balance) FROM public.ledger_account_balances WHERE type='COGS'),    0) AS gross_profit,
  COALESCE((SELECT SUM(balance) FROM public.ledger_account_balances WHERE type='REVENUE'), 0)
   - COALESCE((SELECT SUM(balance) FROM public.ledger_account_balances WHERE type='COGS'),    0)
   - COALESCE((SELECT SUM(balance) FROM public.ledger_account_balances WHERE type='EXPENSE'), 0) AS net_profit;

CREATE VIEW public.ledger_trial_balance WITH (security_invoker = true) AS
SELECT
  COALESCE(SUM(jl.debit_amount),  0) AS total_debits,
  COALESCE(SUM(jl.credit_amount), 0) AS total_credits,
  COALESCE(SUM(jl.debit_amount),  0) - COALESCE(SUM(jl.credit_amount), 0) AS difference,
  (COALESCE(SUM(jl.debit_amount), 0) = COALESCE(SUM(jl.credit_amount), 0)) AS is_balanced
FROM public.journal_lines jl
JOIN public.journal_entries je ON je.id = jl.journal_entry_id
WHERE je.is_reversed = FALSE;

-- =========================================================
-- 9. RLS POLICIES
-- =========================================================
ALTER TABLE public.ledger_accounts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_lines            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounting_periods       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.opening_balance_entries  ENABLE ROW LEVEL SECURITY;

-- ledger_accounts
CREATE POLICY "ledger_accounts read"   ON public.ledger_accounts FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "ledger_accounts insert" ON public.ledger_accounts FOR INSERT
  WITH CHECK (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'accountant'));
CREATE POLICY "ledger_accounts update" ON public.ledger_accounts FOR UPDATE
  USING (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'accountant'));
-- DELETE: no policy = denied

-- journal_entries
CREATE POLICY "journal_entries read"   ON public.journal_entries FOR SELECT
  USING (public.has_role(auth.uid(),'admin')
      OR public.has_role(auth.uid(),'accountant')
      OR public.has_role(auth.uid(),'viewer'));
CREATE POLICY "journal_entries insert" ON public.journal_entries FOR INSERT
  WITH CHECK (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'accountant'));
-- UPDATE allowed (RLS) so reversal-flag flip works; trigger blocks unauthorized field changes
CREATE POLICY "journal_entries update" ON public.journal_entries FOR UPDATE
  USING (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'accountant'));
-- DELETE: denied

-- journal_lines
CREATE POLICY "journal_lines read"   ON public.journal_lines FOR SELECT
  USING (public.has_role(auth.uid(),'admin')
      OR public.has_role(auth.uid(),'accountant')
      OR public.has_role(auth.uid(),'viewer'));
CREATE POLICY "journal_lines insert" ON public.journal_lines FOR INSERT
  WITH CHECK (public.has_role(auth.uid(),'admin') OR public.has_role(auth.uid(),'accountant'));
-- UPDATE/DELETE: denied (trigger also blocks)

-- accounting_periods
CREATE POLICY "periods read"   ON public.accounting_periods FOR SELECT
  USING (public.has_role(auth.uid(),'admin')
      OR public.has_role(auth.uid(),'accountant')
      OR public.has_role(auth.uid(),'viewer'));
CREATE POLICY "periods insert" ON public.accounting_periods FOR INSERT
  WITH CHECK (public.has_role(auth.uid(),'admin'));
CREATE POLICY "periods update" ON public.accounting_periods FOR UPDATE
  USING (public.has_role(auth.uid(),'admin'));

-- opening_balance_entries
CREATE POLICY "opening read"   ON public.opening_balance_entries FOR SELECT
  USING (public.has_role(auth.uid(),'admin')
      OR public.has_role(auth.uid(),'accountant')
      OR public.has_role(auth.uid(),'viewer'));
CREATE POLICY "opening insert" ON public.opening_balance_entries FOR INSERT
  WITH CHECK (public.has_role(auth.uid(),'admin') AND verified_by = auth.uid());

COMMIT;
