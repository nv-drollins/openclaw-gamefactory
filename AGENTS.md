# Agent Notes

This is the RawClaw/OpenClaw-only Game Factory demo.

- Do not add NemoClaw or OpenShell setup steps.
- The host-native Game Factory server listens on `APP_FACTORY_PORT`, default `7866`.
- Generated app artifacts live under `runs/`.
- The OpenClaw profile is `openclaw-gamefactory`.
- The OpenClaw dashboard port is `18793`.
- The OpenClaw skill is `game-factory`.
- The code model defaults to `qwen3-coder:30b`.
- The OpenClaw orchestrator defaults to `gemma4:latest`.
- OpenClaw-driven generate/refine/approve calls should show up in the UI as `Control surface: OpenClaw`.
- Refinements should preserve the current run and create another version rather than starting a new game.
- The `game-factory` skill is shell-driven. Agents should use foreground `exec` with a long timeout to run `python3 scripts/generate-game.py ...`; do not call `subagents` or `process` with `game-factory` as a target.

Keep setup scripts usable on a clean Ubuntu/Spark host and avoid assuming passwordless sudo.
