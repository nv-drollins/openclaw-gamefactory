# OpenClaw Game Factory

RawClaw version of the Game Factory demo: no NemoClaw, no OpenShell, and no sandbox. The app runs directly on the host, uses local Ollama for generation, and exposes a native OpenClaw profile for dashboard-driven workflows.

The browser demo lets a user enter a game idea, then runs a small builder/reviewer/deployer loop:

```text
Browser UI
  -> host-native Game Factory server
  -> local Ollama code model
  -> generated single-file app under ./runs
```

The OpenClaw route adds:

```text
OpenClaw dashboard
  -> game-factory skill
  -> host-native Game Factory API
```

## First Deploy

Run on the Spark or target Ubuntu host:

```bash
git clone https://github.com/nv-drollins/openclaw-gamefactory.git
cd openclaw-gamefactory
chmod +x start.sh stop.sh restart.sh scripts/*.sh scripts/*.py
./scripts/start-demo.sh
```

Open the Game Factory UI:

```text
http://<spark-ip>:7866
```

The OpenClaw dashboard URL and token are printed by the start script. The dashboard is bound to loopback by default, so use the printed SSH tunnel if your browser is on another machine.

## Stop

```bash
./scripts/stop-demo.sh
```

Remove generated app artifacts too:

```bash
./scripts/stop-demo.sh --delete-runs
```

## Restart

```bash
./restart.sh
```

Skip the installer on later runs:

```bash
./scripts/start-demo.sh --no-install
```

## Smoke Tests

Start with direct generation:

```bash
./scripts/start-demo.sh --smoke
```

Test the OpenClaw dashboard route:

```bash
./scripts/start-demo.sh --no-install --agent-smoke
```

You can also drive the server directly:

```bash
./scripts/generate-game.py "Build a small asteroid dodger with score, lives, timer, and restart controls."
```

## OpenClaw Demo Flow

For the best RawClaw demo, put two browser windows side by side:

- Left: OpenClaw dashboard from `scripts/show-dashboard.sh`
- Right: Game Factory UI at `http://<spark-ip>:7866`

Then use OpenClaw as the control surface. The Game Factory UI polls the same backend, so it updates live as OpenClaw takes each action.

1. In OpenClaw, ask:

```text
Use the game-factory skill to build a small rover crystal collector with hazards, score, timer, and restart controls.
```

The UI should show `Control surface: OpenClaw`, the Builder/Reviewer/Deployer flow should run, and the generated game should appear in the preview.

2. Ask for a revision:

```text
Make the hazards brighter, add a pause button, and make the score larger.
```

OpenClaw should use the refine action, not start over. The same run gets a new version and the preview refreshes.

3. Ask for another revision:

```text
Add keyboard instructions and make the win condition more obvious.
```

Multiple revisions are supported. Each refine request preserves the current app and writes the next version under `runs/<run_id>/vN`.

4. Approve the result:

```text
This version looks good. Approve it.
```

OpenClaw should call the approval action, and the UI should move the Human Check step to done.

## Defaults

| Setting | Default | Purpose |
|---|---:|---|
| `APP_FACTORY_PORT` | `7866` | Browser UI and API port |
| `APP_FACTORY_MODEL` | `qwen3-coder:30b` | Code-generation model |
| `APP_FACTORY_PROVIDER` | `ollama` | Model provider used by the Game Factory server |
| `APP_FACTORY_NUM_CTX` | `12288` | Ollama context for code generation |
| `APP_FACTORY_MAX_TOKENS` | `6000` | Generation token budget |
| `OPENCLAW_PROFILE` | `openclaw-gamefactory` | Native OpenClaw profile |
| `OPENCLAW_GATEWAY_PORT` | `18793` | Dashboard port |
| `OPENCLAW_OLLAMA_MODEL` | `gemma4:latest` | Lightweight OpenClaw orchestrator |
| `OPENCLAW_OLLAMA_CONTEXT_WINDOW` | `8192` | OpenClaw orchestrator context cap |

The split model setup is intentional. `qwen3-coder:30b` does the app-building work, while `gemma4:latest` is a smaller OpenClaw orchestrator that stays responsive when the code model is loaded.

## Requirements

The installer handles:

- Ubuntu/Debian host packages: `curl`, `git`, `lsof`, `python3`, `python3-venv`, `python3-pip`, `zstd`
- Node.js 22 through nvm when needed
- OpenClaw CLI through npm when needed
- Ollama 0.22.1 when needed
- Ollama models `qwen3-coder:30b` and `gemma4:latest`

Not required:

- NemoClaw
- OpenShell
- Docker
- vLLM
- Hugging Face token

## Demo Prompt

Try:

```text
Build a compact lane-switch runner where a bike avoids obstacles, collects boosts, tracks score and lives, and has restart controls.
```

After generation, use the Human Check panel to approve or refine:

```text
Make the obstacles easier to see and add a pause button.
```
