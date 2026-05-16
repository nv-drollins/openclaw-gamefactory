#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RUN_INSTALL=1
RUN_SMOKE="${OPENCLAW_RUN_GAMEFACTORY_SMOKE:-0}"
RUN_AGENT_SMOKE="${OPENCLAW_RUN_AGENT_SMOKE:-0}"
APP_PORT="${APP_FACTORY_PORT:-7866}"
APP_HOST="${APP_FACTORY_HOST:-0.0.0.0}"
RUN_DIR="$ROOT/.run"
PID_FILE="$RUN_DIR/gamefactory.pid"
LOG_FILE="$ROOT/logs/gamefactory.log"

usage() {
  cat <<EOF
Usage: $0 [--no-install] [--smoke] [--agent-smoke]

Starts the RawClaw/OpenClaw Game Factory demo:
  - installs clean-instance prerequisites when needed
  - ensures local Ollama models are available
  - starts the host-native Game Factory server
  - configures native OpenClaw and starts the dashboard

Options:
  --no-install   Skip prerequisite installation checks.
  --smoke        Run a direct Game Factory generation smoke test.
  --agent-smoke  Run a native OpenClaw prompt against the game-factory skill.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-install) RUN_INSTALL=0 ;;
    --smoke) RUN_SMOKE=1 ;;
    --agent-smoke) RUN_AGENT_SMOKE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

wait_for_server() {
  for _ in $(seq 1 90); do
    if curl -fsS "http://127.0.0.1:${APP_PORT}/api/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

start_server() {
  mkdir -p "$RUN_DIR" "$ROOT/logs" "$ROOT/runs"

  if curl -fsS "http://127.0.0.1:${APP_PORT}/api/health" >/dev/null 2>&1; then
    echo "Game Factory server already running on port $APP_PORT"
    return 0
  fi

  if command -v lsof >/dev/null 2>&1; then
    existing="$(lsof -tiTCP:"$APP_PORT" -sTCP:LISTEN 2>/dev/null || true)"
    if [ -n "$existing" ]; then
      echo "Port $APP_PORT is already in use by: $existing" >&2
      exit 1
    fi
  fi

  echo "Starting Game Factory server on http://${APP_HOST}:${APP_PORT}"
  (
    cd "$ROOT"
    APP_FACTORY_PROVIDER="${APP_FACTORY_PROVIDER:-ollama}" \
    APP_FACTORY_MODEL="${APP_FACTORY_MODEL:-qwen3-coder:30b}" \
    python3 server.py --host "$APP_HOST" --port "$APP_PORT"
  ) >"$LOG_FILE" 2>&1 &
  echo "$!" > "$PID_FILE"

  if ! wait_for_server; then
    echo "Game Factory server did not become ready. Last log lines:" >&2
    tail -100 "$LOG_FILE" >&2 || true
    exit 1
  fi

  host_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  echo "Game Factory is ready: http://${host_ip:-127.0.0.1}:${APP_PORT}"
  echo "Log: $LOG_FILE"
}

echo "[1/5] Checking host prerequisites"
if [ "$RUN_INSTALL" -eq 1 ]; then
  "$SCRIPT_DIR/install-host-prereqs.sh"
else
  echo "Skipping install step"
fi

echo "[2/5] Ensuring local Ollama models"
"$SCRIPT_DIR/ensure-model.sh"

echo "[3/5] Starting Game Factory"
start_server

echo "[4/5] Configuring native OpenClaw"
"$SCRIPT_DIR/setup-openclaw.sh"
"$SCRIPT_DIR/start-openclaw-gateway.sh"

if [ "$RUN_SMOKE" = "1" ]; then
  echo "[smoke] Direct Game Factory generation"
  "$SCRIPT_DIR/generate-game.py" "Build a compact rover crystal collector with score, hazards, and restart controls." --timeout 900
fi
if [ "$RUN_AGENT_SMOKE" = "1" ]; then
  echo "[smoke] OpenClaw agent route"
  "$SCRIPT_DIR/run-openclaw-smoke.sh"
fi

echo "[5/5] OpenClaw dashboard"
"$SCRIPT_DIR/show-dashboard.sh"

cat <<EOF

Game Factory UI:
  http://$(hostname -I 2>/dev/null | awk '{print $1}'):${APP_PORT}

Try this prompt:
  Build a compact asteroid dodger with score, lives, timer, restart controls, and keyboard movement.

Stop the demo with:
  ./scripts/stop-demo.sh
EOF
