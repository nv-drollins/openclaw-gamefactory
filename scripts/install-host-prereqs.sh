#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=openclaw-env.sh
. "$SCRIPT_DIR/openclaw-env.sh"

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This helper supports Ubuntu/Debian hosts with apt-get." >&2
  echo "Install equivalents manually: ca-certificates curl git lsof python3 python3-pip python3-venv sudo zstd." >&2
  exit 1
fi

bash "$SCRIPT_DIR/ensure-sudo.sh"

sudo apt-get update
sudo apt-get install -y \
  ca-certificates \
  curl \
  git \
  lsof \
  python3 \
  python3-pip \
  python3-venv \
  sudo \
  zstd

openclaw_source_nvm
if [ "$(openclaw_node_major)" -lt 22 ]; then
  echo "[prereqs] Installing nvm + Node.js 22"
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    NVM_VERSION="${NVM_VERSION:-v0.40.3}"
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" -o /tmp/install-nvm.sh
    bash /tmp/install-nvm.sh
  fi
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
  nvm install 22
  nvm alias default 22
  nvm use 22 >/dev/null
fi

openclaw_require_node22

if ! command -v openclaw >/dev/null 2>&1; then
  echo "[prereqs] Installing OpenClaw CLI"
  npm install -g openclaw@latest
else
  echo "[prereqs] OpenClaw already installed: $(openclaw --version)"
fi

if [ "${OPENCLAW_SKIP_OLLAMA_INSTALL:-0}" != "1" ]; then
  bash "$SCRIPT_DIR/install-ollama.sh"
else
  echo "[prereqs] Skipping Ollama install because OPENCLAW_SKIP_OLLAMA_INSTALL=1"
fi

echo "Host prerequisites installed."
