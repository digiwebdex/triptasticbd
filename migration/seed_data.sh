#!/usr/bin/env bash
# Seed default data (idempotent). Safe to rerun.
# Usage: source .env && ./migration/seed_data.sh
set -euo pipefail

: "${DB_HOST:?}" ; : "${DB_PORT:?}" ; : "${DB_NAME:?}" ; : "${DB_USER:?}" ; : "${DB_PASSWORD:?}"
export PGPASSWORD="${DB_PASSWORD}"
PSQL="psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -v ON_ERROR_STOP=1"

echo "==> Seeding chart of accounts (if missing)"
$PSQL <<'SQL'
INSERT INTO public.accounts (name, type, balance)
SELECT v.name, v.type, 0
FROM (VALUES
  ('Cash','asset'),
  ('Bank','asset'),
  ('bKash','asset'),
  ('Nagad','asset'),
  ('Revenue','income'),
  ('Operating Expenses','expense')
) AS v(name,type)
WHERE NOT EXISTS (SELECT 1 FROM public.accounts a WHERE a.name = v.name);
SQL

echo "==> Seeding default cancellation policy"
$PSQL <<'SQL'
INSERT INTO public.cancellation_policies (name, description, refund_type, refund_value, is_default, is_active)
SELECT 'Default', 'Default refund policy', 'percentage', 50, true, true
WHERE NOT EXISTS (SELECT 1 FROM public.cancellation_policies WHERE is_default = true);
SQL

echo "==> Creating admin user (interactive)"
echo "    To create the primary admin run:"
echo "      cd backend && node create-admin.js"
echo "Done."
