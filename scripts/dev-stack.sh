#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

command_name="${1:-reset}"
profile="${2:-core}"

case "$profile" in
  core|database|messaging|broker|all) ;;
  *)
    echo "Unknown profile '$profile'. Use core|database|messaging|broker|all." >&2
    exit 2
    ;;
esac

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command '$1' was not found." >&2
    exit 1
  fi
}

random_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 24
  else
    python3 - <<'PY'
import secrets
print(secrets.token_hex(24))
PY
  fi
}

ensure_env() {
  if [[ -f .env ]]; then
    return
  fi

  cp .env.example .env
  admin_password="$(random_secret)"
  service_password="$(random_secret)"
  artemis_password="$(random_secret)"

  python3 - "$admin_password" "$service_password" "$artemis_password" <<'PY'
from pathlib import Path
import sys

path = Path('.env')
text = path.read_text(encoding='utf-8')
text = text.replace('POSTGRES_ADMIN_PASSWORD=__GENERATE__', f'POSTGRES_ADMIN_PASSWORD={sys.argv[1]}')
text = text.replace('DEV_DATABASE_PASSWORD=__GENERATE__', f'DEV_DATABASE_PASSWORD={sys.argv[2]}')
text = text.replace('ARTEMIS_PASSWORD=__GENERATE__', f'ARTEMIS_PASSWORD={sys.argv[3]}')
path.write_text(text, encoding='utf-8')
PY

  echo "Created .env with generated local-only credentials."
}

load_env() {
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
}

print_endpoints() {
  load_env
  echo
  echo "Local infrastructure profile '$profile' is ready."
  case "$profile" in
    core)
      echo "PostgreSQL: localhost:${POSTGRES_PORT:-5432}"
      echo "Kafka:      localhost:${KAFKA_PORT:-9092}"
      echo "Databases:  ${DEV_DATABASES}"
      ;;
    database)
      echo "PostgreSQL: localhost:${POSTGRES_PORT:-5432}"
      echo "Databases:  ${DEV_DATABASES}"
      ;;
    messaging)
      echo "Kafka:      localhost:${KAFKA_PORT:-9092}"
      ;;
    broker)
      echo "Artemis:    localhost:${ARTEMIS_CORE_PORT:-61616}"
      echo "Console:    http://localhost:${ARTEMIS_WEB_PORT:-8161}"
      ;;
    all)
      echo "PostgreSQL: localhost:${POSTGRES_PORT:-5432}"
      echo "Kafka:      localhost:${KAFKA_PORT:-9092}"
      echo "Artemis:    localhost:${ARTEMIS_CORE_PORT:-61616}"
      echo "Console:    http://localhost:${ARTEMIS_WEB_PORT:-8161}"
      echo "Databases:  ${DEV_DATABASES}"
      ;;
  esac
  echo
  echo "Run application microservices from the IDE and point them at these endpoints."
}

require_command docker
require_command python3
ensure_env

docker compose version >/dev/null
compose=(docker compose --profile "$profile")

case "$command_name" in
  reset)
    docker compose down --volumes --remove-orphans
    "${compose[@]}" up -d --wait
    print_endpoints
    ;;
  up)
    "${compose[@]}" up -d --wait
    print_endpoints
    ;;
  down)
    docker compose down --remove-orphans
    ;;
  clean)
    docker compose down --volumes --remove-orphans
    ;;
  status)
    "${compose[@]}" ps
    ;;
  logs)
    "${compose[@]}" logs --follow
    ;;
  config)
    "${compose[@]}" config
    ;;
  *)
    echo "Usage: $0 [reset|up|down|clean|status|logs|config] [core|database|messaging|broker|all]" >&2
    exit 2
    ;;
esac
