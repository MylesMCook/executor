#!/usr/bin/env sh
# Pull this fork, rebuild the self-host image, restart it, and wait until healthy.
# Run on the server from anywhere inside the clone: ./personal/deploy.sh
set -eu

cd "$(dirname "$0")/.."
git pull --ff-only

cd apps/host-selfhost
docker compose up -d --build

i=0
until curl -fsS http://127.0.0.1:4788/api/health >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -ge 60 ]; then
    echo "Executor did not become healthy; recent logs:" >&2
    docker compose logs --tail 50 >&2
    exit 1
  fi
  sleep 2
done

echo "Executor is healthy on port 4788."
