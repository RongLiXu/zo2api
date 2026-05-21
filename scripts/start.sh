#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

if [ -z "${ZO_ACCESS_TOKEN:-}" ]; then
  echo "ZO_ACCESS_TOKEN is required. Copy .env.example to .env and fill it first." >&2
  exit 1
fi

exec node server.js
