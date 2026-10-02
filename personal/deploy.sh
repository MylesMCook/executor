#!/usr/bin/env sh
# Pull this fork, start the self-host container, and wait until healthy.
# Run on the server from anywhere inside the clone:
#   ./personal/deploy.sh          use upstream's prebuilt image (fast)
#   ./personal/deploy.sh --build  build the image from this fork's source
set -eu

cd "$(dirname "$0")/.."
git pull --ff-only

cd apps/host-selfhost
if [ "${1:-}" = "--build" ]; then
  docker compose up -d --build
else
  docker compose -f docker-compose.yml -f ../../personal/compose.prebuilt.yml up -d
fi

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
