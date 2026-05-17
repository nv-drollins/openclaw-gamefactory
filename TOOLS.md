# Tool Guidance

Use foreground shell exec for Game Factory actions. Generation and refinement usually take 2-4 minutes, so set the exec timeout to at least 900 seconds and wait for the JSON output.

- Generate: `python3 scripts/generate-game.py "<prompt>"`
- Refine the current app: `python3 scripts/generate-game.py --refine "<feedback>"`
- Approve the current app: `python3 scripts/generate-game.py --approve`

Do not call `subagents` or `process` with `game-factory` as a target. Do not use a background process for these commands. `game-factory` is a skill name, and the skill works by running the local helper script against the Game Factory server.
