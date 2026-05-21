#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    echo "Docker Compose is required. Install Docker Desktop or docker compose plugin first." >&2
    exit 1
  fi
}

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required. Install Docker Desktop first." >&2
  exit 1
fi

if [ ! -f .env ]; then
  if [ -n "${ZO_ACCESS_TOKEN:-}" ]; then
    cat > .env <<EOF
ZO_ACCESS_TOKEN=${ZO_ACCESS_TOKEN}
PROXY_API_KEY=${PROXY_API_KEY:-sk-proxy-gateway-v1}
PROXY_PROMPT_OVERRIDE=${PROXY_PROMPT_OVERRIDE:-true}
PROXY_OUTPUT_SANITIZE=${PROXY_OUTPUT_SANITIZE:-false}
PORT=${PORT:-8000}
EOF
    echo "Created .env from current environment."
  else
    cp .env.example .env
    echo "Created .env from .env.example. Fill ZO_ACCESS_TOKEN in .env, then rerun: ./scripts/deploy.sh" >&2
    exit 1
  fi
fi

set -a
. ./.env
set +a

if [ -z "${ZO_ACCESS_TOKEN:-}" ] || [ "${ZO_ACCESS_TOKEN}" = "zo_sk_your_token_here" ]; then
  echo "ZO_ACCESS_TOKEN is required. Fill a real token in .env, then rerun: ./scripts/deploy.sh" >&2
  exit 1
fi

compose up -d --build
compose ps

echo "Deployment complete. Base URL: http://localhost:${PORT:-8000}"
echo "Health check: curl http://localhost:${PORT:-8000}/healthz"
