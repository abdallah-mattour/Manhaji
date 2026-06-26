#!/usr/bin/env bash
set -euo pipefail

PORT="${1:-${MANHAJI_SERVER_PORT:-${PORT:-8080}}}"

if ! command -v lsof >/dev/null 2>&1; then
  echo "lsof is required to inspect port $PORT."
  exit 1
fi

pids="$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)"
if [ -z "$pids" ]; then
  echo "Port $PORT is free."
  exit 0
fi

echo "Port $PORT is currently in use:"
lsof -nP -iTCP:"$PORT" -sTCP:LISTEN || true

echo "Stopping process(es): $pids"
kill $pids 2>/dev/null || true

for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  if ! lsof -tiTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Port $PORT is free."
    exit 0
  fi
  sleep 0.5
done

remaining="$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)"
if [ -n "$remaining" ]; then
  echo "Force-stopping process(es): $remaining"
  kill -9 $remaining 2>/dev/null || true
fi

if lsof -tiTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Could not free port $PORT."
  exit 1
fi

echo "Port $PORT is free."
