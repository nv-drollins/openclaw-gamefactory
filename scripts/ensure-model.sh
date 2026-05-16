#!/usr/bin/env bash
set -euo pipefail

CODE_MODEL="${APP_FACTORY_MODEL:-qwen3-coder:30b}"
ORCH_MODEL="${OPENCLAW_OLLAMA_MODEL:-gemma4:latest}"

if ! command -v ollama >/dev/null 2>&1; then
  echo "Missing ollama. Run ./scripts/install-host-prereqs.sh first." >&2
  exit 1
fi

if ! curl -fsS http://127.0.0.1:11434 >/dev/null 2>&1; then
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart ollama || true
  fi
fi

for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:11434 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! curl -fsS http://127.0.0.1:11434 >/dev/null 2>&1; then
  echo "Ollama is not responding on http://127.0.0.1:11434" >&2
  exit 1
fi

pull_if_missing() {
  local model="$1"
  if ollama list | awk 'NR > 1 {print $1}' | grep -Fxq "$model"; then
    echo "Ollama model already present: $model"
  else
    echo "Pulling Ollama model: $model"
    ollama pull "$model"
  fi
}

pull_if_missing "$CODE_MODEL"
if [ "$ORCH_MODEL" != "$CODE_MODEL" ]; then
  pull_if_missing "$ORCH_MODEL"
fi
