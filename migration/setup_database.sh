#!/usr/bin/env bash
# Create the PostgreSQL database and user for Triptastic
# Usage: source .env && ./migration/setup_database.sh
set -euo pipefail

: "${DB_HOST:?DB_HOST not set}"
: "${DB_PORT:?DB_PORT not set}"
: "${DB_NAME:?DB_NAME not set}"
: "${DB_USER:?DB_USER not set}"
: "${DB_PASSWORD:?DB_PASSWORD not set}"

# Use Postgres superuser for setup (defaults to local 'postgres')
PG_SUPER_USER="${PG_SUPER_USER:-postgres}"
PSQL_ADMIN="psql -h ${DB_HOST} -p ${DB_PORT} -U ${PG_SUPER_USER} -v ON_ERROR_STOP=1"

echo "==> Ensuring role ${DB_USER} exists"
$PSQL_ADMIN -d postgres -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1 || \
  $PSQL_ADMIN -d postgres -c "CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASSWORD}';"

echo "==> Ensuring database ${DB_NAME} exists"
$PSQL_ADMIN -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1 || \
  $PSQL_ADMIN -d postgres -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"

echo "==> Granting privileges"
$PSQL_ADMIN -d "${DB_NAME}" -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
$PSQL_ADMIN -d "${DB_NAME}" -c "GRANT ALL ON SCHEMA public TO ${DB_USER};"
$PSQL_ADMIN -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
$PSQL_ADMIN -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";"

echo "Done. Now run: ./migration/run_migration.sh"
