#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

BUILD_IMAGE=false

case "${1:-}" in
  --build)
    BUILD_IMAGE=true
    ;;
  "" )
    ;;
  -h|--help)
    echo "Usage: ./scripts/deploy.sh [--build]"
    echo ""
    echo "Default: pull/use the image configured in docker-compose.yml and start the container."
    echo "--build: build the image locally before starting."
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    echo "Usage: ./scripts/deploy.sh [--build]" >&2
    exit 1
    ;;
esac

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

if [ "$BUILD_IMAGE" = "true" ]; then
  compose up -d --build
else
  compose up -d --pull missing
fi

compose ps

echo "Deployment complete. Base URL: http://localhost:${PORT:-8000}"
echo "Health check: curl http://localhost:${PORT:-8000}/healthz"
