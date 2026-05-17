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

OPENCLAW_CLI_VERSION="${OPENCLAW_CLI_VERSION:-2026.5.12}"

openclaw_installed_version() {
  openclaw --version 2>/dev/null | grep -Eo 'v?[0-9]{4}\.[0-9]+\.[0-9]+([-.][[:alnum:].]+)?' | head -n 1 | sed 's/^v//'
}

install_openclaw_cli() {
  local installed=""
  if command -v openclaw >/dev/null 2>&1; then
    installed="$(openclaw_installed_version || true)"
  fi

  if [ "$OPENCLAW_CLI_VERSION" != "latest" ] && [ -n "$installed" ] && [ "$installed" = "$OPENCLAW_CLI_VERSION" ]; then
    echo "[prereqs] OpenClaw already installed: $(openclaw --version)"
    return 0
  fi

  if [ -n "$installed" ]; then
    echo "[prereqs] Installing OpenClaw CLI ${OPENCLAW_CLI_VERSION} (current: $(openclaw --version))"
  else
    echo "[prereqs] Installing OpenClaw CLI ${OPENCLAW_CLI_VERSION}"
  fi
  npm install -g "openclaw@${OPENCLAW_CLI_VERSION}"
}

install_openclaw_cli

if [ "${OPENCLAW_SKIP_OLLAMA_INSTALL:-0}" != "1" ]; then
  bash "$SCRIPT_DIR/install-ollama.sh"
else
  echo "[prereqs] Skipping Ollama install because OPENCLAW_SKIP_OLLAMA_INSTALL=1"
fi

echo "Host prerequisites installed."
