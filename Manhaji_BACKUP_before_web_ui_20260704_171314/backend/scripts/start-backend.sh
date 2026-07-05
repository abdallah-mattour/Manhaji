#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PORT="${MANHAJI_SERVER_PORT:-${PORT:-8080}}"

export MANHAJI_SERVER_PORT="$PORT"

"$SCRIPT_DIR/stop-backend-port.sh" "$PORT"

cd "$ROOT_DIR"
chmod +x ./gradlew 2>/dev/null || true

echo "Starting Manhaji backend on http://localhost:$PORT"
echo "Use Ctrl+C to stop it."
exec ./gradlew bootRun
