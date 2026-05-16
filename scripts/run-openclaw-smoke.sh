#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=openclaw-env.sh
. "$SCRIPT_DIR/openclaw-env.sh"

PROFILE="${OPENCLAW_PROFILE:-openclaw-gamefactory}"
MODEL_REF="${OPENCLAW_MODEL_REF:-ollama/${OPENCLAW_OLLAMA_MODEL:-gemma4:latest}}"
SESSION="${OPENCLAW_SMOKE_SESSION:-gamefactory-smoke}"
LOG_FILE="$ROOT/logs/openclaw-smoke.json"
ERR_LOG="$ROOT/logs/openclaw-smoke.stderr.log"

mkdir -p "$ROOT/logs"
openclaw_require_cli

openclaw --profile "$PROFILE" agent \
  --local \
  --session-id "$SESSION" \
  --model "$MODEL_REF" \
  --timeout "${OPENCLAW_AGENT_TIMEOUT:-900}" \
  --message "Use the game-factory skill to generate a tiny browser game where a rover collects crystals and avoids hazards. Return the generated title and URL." \
  --json > "$LOG_FILE" 2>"$ERR_LOG"

python3 - "$LOG_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
text = "\n".join(p.get("text", "") for p in data.get("payloads", [])).strip()
print(text)
if "/apps/" not in text and "http://127.0.0.1" not in text:
    raise SystemExit("OpenClaw smoke response did not include a generated app URL")
PY
