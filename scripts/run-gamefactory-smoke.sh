#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODEL="${APP_FACTORY_MODEL:-qwen3-coder:30b}"

mkdir -p "$ROOT/logs"
APP_FACTORY_PROVIDER="${APP_FACTORY_PROVIDER:-ollama}" \
APP_FACTORY_MODEL="$MODEL" \
python3 "$ROOT/server.py" --smoke-test --model "$MODEL" | tee "$ROOT/logs/gamefactory-smoke.log"
