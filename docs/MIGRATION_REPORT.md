# Triptastic — Supabase → Self-Hosted VPS Migration Report

**Date:** 2026-05-08
**Scope:** Phase 1 — produce all migration deliverables, audit Supabase usage, document residual work. Live production was **not modified**.

---

## 1. What was migrated in this phase

| Deliverable | Location | Status |
|---|---|---|
| Full schema dump | `database/schema.sql` (2,946 lines) | ✅ |
| Functions/triggers dump | `database/functions.sql` (1,691 lines) | ✅ |
| Indexes | `database/indexes.sql` (151 lines) | ✅ |
| Constraints/FKs | `database/constraints.sql` (258 lines) | ✅ |
| Data export | `database/data.sql` (594 lines) | ✅ |
| Full single-file backup | `backup/supabase_full_backup/full_dump.sql` | ✅ |
| Edge function source backup | `backup/supabase_full_backup/supabase_source/` | ✅ |
| Setup / migrate / seed scripts | `migration/*.sh` | ✅ |
| Postgres connection layer | `backend/db/index.js` | ✅ |
| Edge-function router skeleton | `backend/api/index.js` + 17 handlers (1 ported, 16 stubs) | ✅ |
| Env template | `.env.example` | ✅ |
| Container build | `Dockerfile`, `docker-compose.yml` | ✅ |
| Deployment guide | `docs/README_DEPLOYMENT.md` | ✅ |
| This report | `docs/MIGRATION_REPORT.md` | ✅ |

---

## 2. Source database snapshot (row counts)

Captured from Supabase pooler at migration time. Almost all business tables are empty in this Supabase environment — production data lives in the **VPS Postgres on port 5440** (separate from this Supabase project).

| Table | Rows |
|---|---|
| packages | 19 |
| profiles | 1 |
| user_roles | 1 |
| (all other 41 tables) | 0 |

> **Validation note:** When restoring on a new VPS, run `migration/run_migration.sh` and compare `pg_stat_user_tables.n_live_tup` against the values above.

---

## 3. Edge function audit (17 functions)

Source: `supabase/functions/<name>/index.ts` → Target: `backend/api/<name>.js` mounted at `POST /api/<name>`.

| # | Function | Converted | Notes |
|---|---|---|---|
| 1 | `verify-invoice` | ✅ Ported (reference impl.) | `backend/api/verify-invoice.js` |
| 2 | `track-booking` | ⏳ Stub | Mirrors the existing logic in `server/index.js` `/track-booking` route — port directly. |
| 3 | `send-otp` | ⏳ Stub | Server already implements OTP via `server/services/twoFactor.js`. |
| 4 | `send-notification` | ⏳ Stub | Wrap `server/services/dueReminder.js` notifier. |
| 5 | `send-reminder` | ⏳ Stub | |
| 6 | `check-due-alerts` | ⏳ Stub | Cron — replace with `node-cron` in `server/index.js`. |
| 7 | `create-guest-booking` | ⏳ Stub | Existing endpoint in `server/index.js`. |
| 8 | `upload-booking-document` | ⏳ Stub | Replace Supabase Storage with `multer` + `/server/uploads/`. |
| 9 | `booking-notifications` | ⏳ Stub | |
| 10 | `admin-create-user` | ⏳ Stub | Replace with bcryptjs + JWT (`server/routes/auth.js`). |
| 11 | `admin-manage-user` | ⏳ Stub | |
| 12 | `daily-backup` | ⏳ Stub | Replace with `server/backup-to-gdrive.sh` cron. |
| 13 | `daily-summary-sms` | ⏳ Stub | |
| 14 | `site-backup` | ⏳ Stub | Use `pg_dump`. |
| 15 | `site-restore` | ⏳ Stub | Use `psql -f`. |
| 16 | `fb-conversions-api` | ⏳ Stub | Direct HTTP POST to Facebook Graph. |

---

## 4. Frontend Supabase references found (audit)

19 files still import from Supabase. They must be rewritten to use `@/lib/api` or the new `/api/*` endpoints.

```
server/MIGRATION_NOTES.md                           (doc only)
server/index.js                                     (legacy fallback comments)
src/components/BookingDialog.tsx
src/components/admin/AdminUserManager.tsx
src/components/admin/BannerImageUpload.tsx          (Supabase Storage)
src/components/admin/SignatureSettingsManager.tsx   (Supabase Storage)
src/integrations/supabase/client.ts                 (auto-generated, must be neutralised)
src/lib/api.ts                                      (bridge — fallback logic to remove)
src/lib/fbPixel.ts                                  (calls fb-conversions-api edge fn)
src/pages/Auth.tsx
src/pages/Booking.tsx
src/pages/TrackBooking.tsx
src/pages/VerifyInvoice.tsx
src/pages/admin/AdminBookingsPage.tsx
src/pages/admin/AdminDueAlertsPage.tsx
src/pages/admin/AdminNotificationsPage.tsx
src/pages/admin/AdminPackagesPage.tsx
src/pages/admin/AdminPaymentMethodsPage.tsx
src/pages/admin/AdminSeoPage.tsx
```

### Search patterns (final removal checklist)

```bash
rg -n 'supabase\.functions\.invoke|@supabase/supabase-js|integrations/supabase|supabase\.co' src/
rg -n 'SUPABASE_URL|SUPABASE_ANON_KEY|SUPABASE_SERVICE_ROLE_KEY|VITE_SUPABASE' .
```

The migration is complete only when **both commands return zero matches** in `src/` and the env files.

---

## 5. Manual steps required on the VPS

1. Place the contents of this repo at `/var/www/Triptastic/`.
2. Copy `.env.example` → `.env` and fill real values (DB password, JWT secret, SMTP, SSLCommerz).
3. `chmod +x migration/*.sh`.
4. Provision Postgres role/DB: `./migration/setup_database.sh`.
5. Restore: `./migration/run_migration.sh`.
6. Seed defaults: `./migration/seed_data.sh`.
7. Build frontend: `npm install && npm run build`.
8. Start backend: `pm2 start server/index.js --name triptastic-api`.
9. Configure Nginx vhost (see `docs/README_DEPLOYMENT.md` §4).

---

## 6. Phase 2 — remaining work (NOT done in this phase to protect live site)

- Port the 16 stubbed edge functions to real Node implementations under `backend/api/`.
- Strip Supabase fallback logic from `src/lib/api.ts`.
- Replace `src/integrations/supabase/client.ts` with a neutralised stub or delete it once no imports remain.
- Rewrite the 19 frontend files above to call `/api/*` directly.
- Delete `supabase/` folder.
- Remove `@supabase/supabase-js` from `package.json` and re-run `npm install`.
- Remove `VITE_SUPABASE_*` from `.env`.

---

## 7. Assumptions & placeholder values

- VPS database port: **5440** (already in use by current production).
- Backend port: **3045** (already in use by current production).
- Postgres superuser for `setup_database.sh`: **`postgres`** (override via `PG_SUPER_USER`).
- All passwords/secrets in `.env.example` are placeholders — replace before deploying.

---

## 8. Final no-Supabase checklist (run after Phase 2)

- [ ] `rg supabase src/` returns 0 matches
- [ ] `rg @supabase package.json` returns 0 matches
- [ ] No `VITE_SUPABASE_*` in `.env`
- [ ] `supabase/` folder deleted
- [ ] All 17 endpoints respond at `/api/<name>`
- [ ] Row counts on VPS match the table in §2 (or current production)
- [ ] Site loads and admin can log in via self-hosted JWT

---

## Migration Loop 1 — fb-conversions-api (completed)

**Date:** 2026-05-08
**Edge function migrated:** `fb-conversions-api`

### Changes
- **Backend (`server/index.js`):** Added `POST /api/fb-conversions-api` route. Uses Node `crypto.createHash('sha256')` instead of `crypto.subtle.digest` (Web Crypto). Same request/response shape as the original Deno function. Reads `FB_CONVERSIONS_API_TOKEN` and `FB_PIXEL_ID` from `process.env`.
- **Frontend (`src/lib/api.ts`):** Added `'fb-conversions-api'` to `vpsRoutes`. Calls from `src/lib/fbPixel.ts` now hit the VPS endpoint first; Supabase fallback is disabled (since `allowEdgeFallback` is only true for `send-otp`).

### Required on VPS
Add to `/var/www/Triptastic/server/.env`:
```
FB_CONVERSIONS_API_TOKEN=<existing token from Supabase secrets>
FB_PIXEL_ID=<existing pixel id from Supabase secrets>
```
Then: `pm2 restart triptastic-api`

### Verification
- Test: `curl -X POST https://triptastic.com.bd/api/fb-conversions-api -H 'Content-Type: application/json' -d '{"event_name":"PageView","test_event_code":"TEST123"}'`
- Expected: `{"success":true,"events_received":1,...}` (or 500 if env vars not yet set on VPS).
- Browser: trigger any pixel event, confirm POST to `/api/fb-conversions-api` returns 200.

### Cleanup (do NOT do yet)
- Keep `supabase/functions/fb-conversions-api/` deployed until VPS env vars are confirmed and Network tab shows successful VPS calls in production for ≥24h.
- Then: delete `supabase/functions/fb-conversions-api/` + call `delete_edge_functions` tool.

### Status
- Code ✅
- VPS env vars ⏳ (user must add)
- Production verification ⏳

---

### Remaining edge functions still on Supabase
| Function | Frontend caller | Migration priority |
|---|---|---|
| `admin-create-user` | `AdminUserManager.tsx` (via `auth/admin/create-user`) | Already routed to VPS via `/api/auth/admin/...` |
| `admin-manage-user` | `AdminUserManager.tsx` (via `auth/admin/manage-user`) | Already routed to VPS via `/api/auth/admin/...` |
| `check-due-alerts` | Cron only | Low — port to node-cron in a later loop |
| `daily-backup` | Cron only | Low — replace with `server/backup-to-gdrive.sh` |
| `daily-summary-sms` | Cron only | Low — port to node-cron |
| `site-backup` | Admin UI (BackupRestoreManager) | Already on VPS — see Loop 2 |
| `site-restore` | Admin UI (BackupRestoreManager) | Already on VPS — see Loop 2 |

---

## Migration Loop 2 — site-backup + site-restore (completed)

**Date:** 2026-05-08
**Edge functions migrated:** `site-backup`, `site-restore`

### Discovery
These edge functions were **already fully migrated** in the original VPS setup. No code changes were required in this loop.

### Current state
- **Backend (`server/index.js`):** `POST /api/backup/create`, `POST /api/backup/restore`, `GET /api/backup/list`, `GET /api/backup/download`, `POST /api/backup/delete` — all implemented using local filesystem (`server/backups/`) and direct PostgreSQL queries.
- **Frontend (`src/components/admin/BackupRestoreManager.tsx`):** Uses direct `fetch()` to `/api/backup/*` endpoints. Does **not** call `supabase.functions.invoke()`.
- **`src/lib/api.ts`:** No backup-related entries in `vpsRoutes` or `functions.invoke()` — no changes needed.

### Differences from original Supabase edge functions
| Aspect | Supabase edge function | VPS endpoint |
|---|---|---|
| Storage location | Supabase Storage bucket `site-backups` | Local filesystem `server/backups/` |
| Backup format | `{ created_at, tables, stats }` JSON | Same format, compatible |
| Restore mode `full` | Delete via `.delete().gte("id", ...)` then `upsert` | `DELETE FROM table` then `INSERT ... ON CONFLICT (id) DO UPDATE` |
| Restore mode `merge` | `upsert(batch, { onConflict: "id" })` | `INSERT ... ON CONFLICT (id) DO UPDATE` |
| Response shape | `{ success, fileName, stats, size }` / `{ success, mode, results }` | `{ success, fileName, tables, size }` / `{ success, restored, mode, results }` — **compatible** with frontend |

### Verification
- Open Admin → Settings → Backup & Restore.
- Click **New Backup** — should create `.json` file in `server/backups/`.
- Click **Download** — file should download with valid JSON content.
- Click **Merge Restore** or **Full Restore** — should restore data without errors.

### Cleanup (do NOT do yet)
- Keep `supabase/functions/site-backup/` and `supabase/functions/site-restore/` deployed until backup/restore is tested in production.
- Then delete both folders and call `delete_edge_functions` tool.

### Status
- Code (frontend) ✅ (already using VPS)
- Code (backend) ✅ (already implemented)
- Production verification ⏳ (test after next deploy)

---

### Remaining edge functions still on Supabase
| Function | Frontend caller | Migration priority |
|---|---|---|
| `admin-create-user` | `AdminUserManager.tsx` (via `auth/admin/create-user`) | Already routed to VPS via `/api/auth/admin/...` |
| `admin-manage-user` | `AdminUserManager.tsx` (via `auth/admin/manage-user`) | Already routed to VPS via `/api/auth/admin/...` |
| `check-due-alerts` | Cron only | Low — port to node-cron in a later loop |
| `daily-backup` | Cron only | Low — replace with `server/backup-to-gdrive.sh` |
| `daily-summary-sms` | Cron only | Low — port to node-cron |
| `send-notification` | AdminNotificationsPage | Medium |
| `send-reminder` | AdminDueAlertsPage | Medium |
| `booking-notifications` | Booking flow | Medium |
| `upload-booking-document` | BookingDialog, DocumentUploadStep | Medium |
| `track-booking` | TrackBooking page | Medium — already has `/api/track-booking` route |
| `create-guest-booking` | Booking flow | Medium — already has `/api/create-guest-booking` route |
