#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PORT="${APP_FACTORY_PORT:-7866}"
RUN_DIR="$ROOT/.run"
PID_FILE="$RUN_DIR/gamefactory.pid"
DELETE_RUNS=0
STOP_GATEWAY="${STOP_GATEWAY:-true}"

usage() {
  cat <<EOF
Usage: $0 [--delete-runs]

Stops the RawClaw/OpenClaw Game Factory server and OpenClaw gateway.

Options:
  --delete-runs  Also remove generated app artifacts under ./runs.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --delete-runs) DELETE_RUNS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

stop_server() {
  pids=""
  if [ -f "$PID_FILE" ]; then
    pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      pids="$pid"
    fi
  fi
  if command -v lsof >/dev/null 2>&1; then
    port_pids="$(lsof -tiTCP:"$APP_PORT" -sTCP:LISTEN 2>/dev/null || true)"
    if [ -n "$port_pids" ]; then
      pids="${pids}${pids:+ }${port_pids}"
    fi
  fi
  pids="$(tr ' ' '\n' <<<"$pids" | awk 'NF && !seen[$0]++' | xargs echo || true)"
  if [ -z "$pids" ]; then
    echo "No Game Factory server found on port $APP_PORT"
  else
    echo "Stopping Game Factory server process(es): $pids"
    kill $pids 2>/dev/null || true
    sleep 2
    for pid in $pids; do
      if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true
      fi
    done
  fi
  rm -f "$PID_FILE"
}

stop_gateway() {
  if [ "$STOP_GATEWAY" != "true" ]; then
    echo "STOP_GATEWAY=false; leaving OpenClaw gateway running."
    return 0
  fi
  if [ -f "$ROOT/logs/openclaw-gateway.pid" ]; then
    pid="$(cat "$ROOT/logs/openclaw-gateway.pid" 2>/dev/null || true)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      echo "Stopping OpenClaw gateway pid $pid"
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$ROOT/logs/openclaw-gateway.pid"
  fi
}

stop_server
stop_gateway

if [ "$DELETE_RUNS" -eq 1 ]; then
  echo "Removing generated runs"
  rm -rf "$ROOT/runs"
fi

echo "Stopped."
