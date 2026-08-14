#!/usr/bin/env bash
set -Eeuo pipefail

: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${DEV_DATABASES:?DEV_DATABASES is required}"
: "${DEV_DATABASE_PASSWORD:?DEV_DATABASE_PASSWORD is required}"

is_identifier() {
  [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
}

IFS=',' read -r -a database_specs <<< "$DEV_DATABASES"

for spec in "${database_specs[@]}"; do
  spec="${spec//[[:space:]]/}"
  database="${spec%%:*}"
  owner="${spec#*:}"

  if [[ "$spec" != *:* || -z "$database" || -z "$owner" ]]; then
    echo "Invalid DEV_DATABASES entry: '$spec'. Expected database:owner." >&2
    exit 1
  fi

  if ! is_identifier "$database" || ! is_identifier "$owner"; then
    echo "Unsafe database or owner identifier in '$spec'." >&2
    exit 1
  fi

  echo "Creating local development database '$database' owned by '$owner'"

  psql --set=ON_ERROR_STOP=1 \
       --username "$POSTGRES_USER" \
       --dbname postgres \
       --set=database="$database" \
       --set=owner="$owner" \
       --set=service_password="$DEV_DATABASE_PASSWORD" <<'EOSQL'
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'owner', :'service_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'owner')
\gexec

SELECT format('CREATE DATABASE %I OWNER %I', :'database', :'owner')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'database')
\gexec
EOSQL

done
