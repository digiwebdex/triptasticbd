# Phase 1 — Double-Entry Ledger Migration Plan
**Status:** DRAFT — awaiting approval before any DB change
**Approach:** Parallel system. Legacy data untouched. Single Opening Balance entry bridges old → new world.

---

## 1. Cutover Model

- **`ledger_start_date`**: Stored in `company_settings` under key `ledger_start_date` (date string).
- All journal entries MUST satisfy `entry_date >= ledger_start_date`. Enforced by trigger.
- Anything before this date → legacy tables only, displayed with a "Legacy" badge.
- No automatic backfill. Ever.

---

## 2. New Tables (additive — no existing tables modified)

### 2.1 `ledger_accounts` (Chart of Accounts)
> **Note:** existing `accounts` table is kept for legacy wallet logic. New COA uses a separate name to avoid breaking triggers.

```
id              uuid PK
code            varchar(10) UNIQUE NOT NULL
name            varchar(255) NOT NULL
type            varchar(20) CHECK (ASSET|LIABILITY|EQUITY|REVENUE|COGS|EXPENSE)
parent_id       uuid REFERENCES ledger_accounts
normal_balance  varchar(6) CHECK (DEBIT|CREDIT)
is_active       boolean DEFAULT true
legacy_wallet_id uuid  -- optional link to old accounts.id for wallet accounts (1100/1200/1210/1220)
created_at      timestamptz DEFAULT now()
```

Seeded with the full 33-account COA from the spec (1100…6700).

### 2.2 `journal_entries`
```
id, entry_number (JE-YYYY-NNNNNN, sequence), entry_date,
description, reference_type, reference_id,
posted_at, posted_by (FK auth.users),
is_reversed, reversed_by_entry_id, period_locked
```

### 2.3 `journal_lines`
```
id, journal_entry_id (FK CASCADE),
account_id (FK ledger_accounts),
debit_amount, credit_amount  (CHECK exactly one > 0),
currency DEFAULT 'BDT', exchange_rate DEFAULT 1,
description
```

### 2.4 `accounting_periods`
```
id, period_year int, period_month int,
status (open|closed), closed_at, closed_by,
trial_balance_snapshot jsonb
UNIQUE(period_year, period_month)
```

### 2.5 `opening_balance_entries` (audit trail of the one-time bridge entry)
```
id, ledger_start_date, journal_entry_id,
verified_by, verification_notes,
breakdown jsonb  -- {cash, bank, bkash, nagad, customer_dues:[...], supplier_payables:[...]}
created_at
```

---

## 3. Triggers (non-negotiable safety)

| Trigger | Table | Action |
|---|---|---|
| `enforce_journal_balance` | journal_lines AFTER INS/UPD/DEL | SUM(debit) = SUM(credit) per entry, else RAISE |
| `enforce_ledger_start_date` | journal_entries BEFORE INS | reject if entry_date < ledger_start_date |
| `block_journal_edits` | journal_entries BEFORE UPD | reject if posted_at IS NOT NULL (except `is_reversed` flag flip) |
| `block_journal_line_edits` | journal_lines BEFORE UPD/DEL | reject if parent entry posted |
| `block_period_locked` | journal_entries BEFORE INS/UPD | reject if entry's period is closed |
| `prevent_audit_log_mutation` | audit_logs | already revokes UPD/DEL — verify |

**Reversal rule:** Cancellation creates a NEW journal entry with negated lines and sets `reversed_by_entry_id` on the original. Original is never edited.

---

## 4. Views (single source of truth)

```sql
ledger_account_balances   -- per-account DR/CR totals + signed balance
ledger_wallet_balances    -- subset for codes 1100, 1200, 1210, 1220
ledger_profit_loss        -- revenue − cogs − expense
ledger_trial_balance      -- DR total, CR total, difference (must = 0)
```

All dashboard KPI queries (post-cutover toggle) read these views directly. No stored aggregates.

---

## 5. RLS

All new tables: enable RLS.
- SELECT: `admin` OR `accountant` OR `viewer`
- INSERT/UPDATE: `admin` OR `accountant` only
- DELETE: revoked entirely (use reversal)

---

## 6. UI Changes (Phase 1 only)

1. **Settings → Ledger** page (admin only)
   - Display current `ledger_start_date` (or "not set")
   - Form to set it (one-time, requires confirm + 2FA-style "type DATE to confirm")
   - Show Trial Balance live (from `ledger_trial_balance` view)
2. **Opening Balance Entry form** (only available when `ledger_start_date` set and no opening entry exists yet)
   - Manual inputs: Cash, Bank, bKash, Nagad
   - Add-rows: Outstanding Customer Dues (customer + amount)
   - Add-rows: Outstanding Supplier Payables (supplier + amount)
   - Live preview of journal lines with offset to `3100 Owner's Capital`
   - "Post Opening Balance" button → creates ONE balanced journal entry, marked `reference_type='opening_balance'`
3. **Chart of Accounts** page — read-only listing of the 33 accounts with current balances
4. **Journal Entries** page — list/search/filter posted entries with full DR/CR drill-down
5. **Reports → Period Toggle** — dropdown: `Legacy period` | `Ledger period` | `Combined view`
   - Default: Ledger period (if cutover set), else Legacy
   - Combined: legacy figures shown as plain rows + ledger figures with audit link
6. **Legacy badge** — small chip on any record (booking/payment/expense) where `created_at < ledger_start_date`
7. **Dashboard banner** — "📒 Ledger active since: 03 May 2026" when set

**Existing modules: ZERO behavior change in Phase 1.** Bookings, payments, expenses still write to their current tables only. The wiring of those events into `journal_entries` is **Phase 2** (separate approval).

---

## 7. What is NOT changing in Phase 1

- ❌ `accounts`, `payments`, `bookings`, `expenses`, etc. — schema unchanged
- ❌ All existing wallet triggers — unchanged
- ❌ `financial_summary`, `daily_cashbook` — unchanged
- ❌ Existing reports — keep working as today
- ❌ No column rename to `legacy_wallet_balance` yet (will revisit at Phase 2 cutover; renaming now risks breaking ~40 files)

> The "rename to legacy_*" step from your rules is deferred to Phase 2 to avoid simultaneous breakage. Phase 1 is purely additive.

---

## 8. Files to be created/changed (Phase 1)

**New SQL migration:** `supabase/migrations/<ts>_ledger_phase1.sql`
- 5 new tables, 6 triggers, 4 views, RLS policies, COA seed (33 rows)

**New frontend files:**
- `src/pages/admin/AdminLedgerSettingsPage.tsx`
- `src/pages/admin/AdminChartOfAccountsLedgerPage.tsx` (separate from existing Chart of Accounts page)
- `src/pages/admin/AdminJournalEntriesPage.tsx`
- `src/pages/admin/AdminOpeningBalancePage.tsx`
- `src/components/admin/LedgerStatusBanner.tsx`
- `src/components/admin/LegacyBadge.tsx`
- `src/lib/ledger.ts` — typed helpers (postJournalEntry, fetchTrialBalance, etc.)

**Edited:**
- `src/App.tsx` — 4 new routes
- `src/components/admin/AdminSidebar.tsx` — new "Ledger" submenu (under Accounting)
- `src/pages/admin/AdminDashboardPage.tsx` — mount `<LedgerStatusBanner />`

**No edits to:** existing booking/payment/expense pages, existing accounting page, any trigger function on the legacy tables.

---

## 9. Acceptance criteria for Phase 1 sign-off

1. ✅ Migration applies cleanly; no existing functionality breaks (smoke test: create booking, record payment, view dashboard).
2. ✅ Without `ledger_start_date` set: ledger UI shows "Not active" state. Nothing else changes.
3. ✅ Setting `ledger_start_date` succeeds; banner appears.
4. ✅ Opening Balance form refuses to post unless DR = CR.
5. ✅ Posted journal entry cannot be edited or deleted (verified via direct SQL — should RAISE).
6. ✅ `ledger_trial_balance` view returns difference = 0 after Opening Balance posted.
7. ✅ Attempting to post entry with `entry_date < ledger_start_date` is rejected.
8. ✅ Attempting to post a manually unbalanced entry is rejected.
9. ✅ Legacy badge appears on records older than cutover date.
10. ✅ Reports period toggle switches view; no data corruption.

---

## 10. Rollback plan

Phase 1 is fully additive. Rollback = `DROP TABLE` the 5 new tables + drop triggers/views + revert UI files. Zero impact on legacy data.

---

## Next step

Reply **"approve plan"** and I will:
1. Create the migration SQL (you'll review & approve before it runs).
2. After migration succeeds, build the UI files.

Reply with edits if you want changes to scope/naming/UI flow first.
