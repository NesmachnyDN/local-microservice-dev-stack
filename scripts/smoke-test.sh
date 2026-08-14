#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo '.env is missing; start the stack through dev-stack first.' >&2
  exit 1
fi

# shellcheck disable=SC1091
set -a
source .env
set +a

expected_databases="${DEV_DATABASES}"
IFS=',' read -r -a specs <<< "$expected_databases"

for spec in "${specs[@]}"; do
  database="${spec%%:*}"
  database="${database//[[:space:]]/}"
  [[ "$database" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || { echo "Unsafe database identifier in smoke test." >&2; exit 1; }
  found="$(docker compose exec -T postgres psql -U "${POSTGRES_ADMIN_USER:-dev_admin}" -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname='${database}'")"
  [[ "$found" == "1" ]] || { echo "Database '$database' was not created." >&2; exit 1; }
done

topic="portfolio-smoke-test"
docker compose exec -T kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create --if-not-exists \
  --topic "$topic" \
  --partitions 1 \
  --replication-factor 1 >/dev/null

docker compose exec -T kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --list | grep -Fx "$topic" >/dev/null

echo 'Smoke test passed: PostgreSQL databases and Kafka are operational.'
