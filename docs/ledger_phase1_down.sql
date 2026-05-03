-- =====================================================================
-- PHASE 1 — DOUBLE-ENTRY LEDGER ROLLBACK
-- Restores the database to the state before ledger_phase1_up.sql.
-- Safe: only touches Phase 1 objects. Existing tables/triggers untouched.
-- =====================================================================

BEGIN;

-- 1. Drop views first (depend on tables)
DROP VIEW IF EXISTS public.ledger_trial_balance;
DROP VIEW IF EXISTS public.ledger_profit_loss;
DROP VIEW IF EXISTS public.ledger_wallet_balances;
DROP VIEW IF EXISTS public.ledger_account_balances;

-- 2. Drop helper function
DROP FUNCTION IF EXISTS public.post_journal_entry(TEXT, DATE, VARCHAR, UUID, JSONB);

-- 3. Drop triggers (must drop before their functions)
DROP TRIGGER IF EXISTS trg_lock_ledger_start_date     ON public.company_settings;
DROP TRIGGER IF EXISTS trg_enforce_ledger_start_date  ON public.journal_entries;
DROP TRIGGER IF EXISTS trg_block_journal_edits        ON public.journal_entries;
DROP TRIGGER IF EXISTS trg_block_journal_line_edits   ON public.journal_lines;
DROP TRIGGER IF EXISTS trg_enforce_journal_balance    ON public.journal_lines;

-- 4. Drop trigger functions
DROP FUNCTION IF EXISTS public.lock_ledger_start_date();
DROP FUNCTION IF EXISTS public.enforce_ledger_start_date();
DROP FUNCTION IF EXISTS public.block_journal_edits();
DROP FUNCTION IF EXISTS public.block_journal_line_edits();
DROP FUNCTION IF EXISTS public.enforce_journal_balance();

-- 5. Drop tables (children → parents)
DROP TABLE IF EXISTS public.opening_balance_entries CASCADE;
DROP TABLE IF EXISTS public.journal_lines           CASCADE;
DROP TABLE IF EXISTS public.journal_entries         CASCADE;
DROP TABLE IF EXISTS public.accounting_periods      CASCADE;
DROP TABLE IF EXISTS public.ledger_accounts         CASCADE;

-- 6. Drop sequence
DROP SEQUENCE IF EXISTS public.journal_entry_seq;

-- 7. Remove ledger setting (safe — only deletes the one key)
DELETE FROM public.company_settings WHERE setting_key = 'ledger_start_date';

COMMIT;
