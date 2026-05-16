# Prerequisites

Tracked for clean Spark / Ubuntu installs.

## Host Packages

- `bash`
- `ca-certificates`
- `curl`
- `git`
- `lsof`
- `python3`
- `python3-pip`
- `python3-venv`
- `sudo`
- `zstd`

Installed by:

```bash
bash scripts/install-host-prereqs.sh
```

## Runtime Tools

- Node.js 22 and npm, installed through nvm if missing.
- OpenClaw CLI, installed through npm if missing.
- Ollama 0.22.1 or newer enough to serve the configured models.

## Models

- Code generation: `qwen3-coder:30b`
- OpenClaw orchestration: `gemma4:latest`

Pulled by:

```bash
bash scripts/ensure-model.sh
```

## Ports

- `7866`: Game Factory browser UI and API.
- `18793`: native OpenClaw dashboard on loopback by default.

## Not Required

- NemoClaw
- OpenShell
- Docker
- vLLM
- Hugging Face token
