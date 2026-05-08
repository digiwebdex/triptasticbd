#!/usr/bin/env bash
# Restore Triptastic database from SQL files
# Usage: source .env && ./migration/run_migration.sh
set -euo pipefail

: "${DB_HOST:?}" ; : "${DB_PORT:?}" ; : "${DB_NAME:?}" ; : "${DB_USER:?}" ; : "${DB_PASSWORD:?}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PGPASSWORD="${DB_PASSWORD}"
PSQL="psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -v ON_ERROR_STOP=1"

run() {
  local file="$1"
  echo "==> Importing $file"
  $PSQL -f "${ROOT}/database/${file}"
}

run schema.sql
run functions.sql
run data.sql
run indexes.sql
run constraints.sql

echo "==> Verifying row counts"
$PSQL -c "SELECT schemaname, relname, n_live_tup AS rows FROM pg_stat_user_tables ORDER BY n_live_tup DESC LIMIT 30;"

TABLES=$($PSQL -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';")
echo "Total tables in public schema: ${TABLES}"
echo "Migration complete."
