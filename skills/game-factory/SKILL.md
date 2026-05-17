---
name: game-factory
description: Run scripts/generate-game.py with the shell exec tool to generate, refine, or approve a RawClaw Game Factory app. Do not invoke game-factory as a subagent target.
version: 1.0.0
metadata:
  openclaw:
    requires:
      bins: ["python3"]
---

# Game Factory

Use this skill when the user asks to generate, build, create, revise, approve, or refine a small browser game or single-file web app.

This is a shell-driven skill, not a subagent. Do not call `subagents` or `process` with a target named `game-factory`. Use the foreground shell `exec` tool from the repository root, set the command timeout to at least 900 seconds, wait for the script to finish, then report the JSON result.

The local Game Factory server must already be running on:

```text
http://127.0.0.1:7866
```

Generate a new app:

```bash
python3 scripts/generate-game.py "Build a compact asteroid dodger with score, lives, timer, and restart controls."
```

Refine the current app. This preserves the same run and creates the next version. You can do this repeatedly for multiple revisions to the same game:

```bash
python3 scripts/generate-game.py --refine "Make hazards easier to see and add a pause button."
```

Approve the current version:

```bash
python3 scripts/generate-game.py --approve
```

Decision rules:

- If the user asks for a new game or app, run a normal generate command with their prompt.
- If the user asks to change, revise, tweak, improve, or add something to the current game, use `--refine`.
- If the user says it is good, approved, final, or ready, use `--approve`.
- Do not use `--refine` before a game has been generated; ask the user for an initial game prompt or generate one first.

The tool returns JSON containing the generated title, summary, review notes, controller, last action, and URL. Report those fields to the user and do not invent a URL.
