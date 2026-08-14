#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

command_name="${1:-reset}"

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

  python3 - "$admin_password" "$service_password" <<'PY'
from pathlib import Path
import sys

path = Path('.env')
text = path.read_text(encoding='utf-8')
text = text.replace('POSTGRES_ADMIN_PASSWORD=__GENERATE__', f'POSTGRES_ADMIN_PASSWORD={sys.argv[1]}')
text = text.replace('DEV_DATABASE_PASSWORD=__GENERATE__', f'DEV_DATABASE_PASSWORD={sys.argv[2]}')
path.write_text(text, encoding='utf-8')
PY

  echo "Created .env with generated local-only credentials."
}

print_endpoints() {
  # shellcheck disable=SC1091
  set -a
  source .env
  set +a
  cat <<EOF2
Local infrastructure is ready.
PostgreSQL: localhost:${POSTGRES_PORT:-5432}
Kafka:      localhost:${KAFKA_PORT:-9092}
Databases:  ${DEV_DATABASES}

Run application microservices from the IDE and point them at these endpoints.
EOF2
}

require_command docker
require_command python3
ensure_env

docker compose version >/dev/null

case "$command_name" in
  reset)
    docker compose down --volumes --remove-orphans
    docker compose up -d --wait
    print_endpoints
    ;;
  up)
    docker compose up -d --wait
    print_endpoints
    ;;
  down)
    docker compose down --remove-orphans
    ;;
  clean)
    docker compose down --volumes --remove-orphans
    ;;
  status)
    docker compose ps
    ;;
  logs)
    docker compose logs --follow
    ;;
  config)
    docker compose config
    ;;
  *)
    echo "Usage: $0 [reset|up|down|clean|status|logs|config]" >&2
    exit 2
    ;;
esac
