---
name: game-factory
description: Generate or refine a small browser game/web app through the local RawClaw Game Factory server.
version: 1.0.0
metadata:
  openclaw:
    requires:
      bins: ["python3"]
---

# Game Factory

Use this skill when the user asks to generate, build, create, revise, or refine a small browser game or single-file web app.

The local Game Factory server must already be running on:

```text
http://127.0.0.1:7866
```

Generate a new app:

```bash
python3 scripts/generate-game.py "Build a compact asteroid dodger with score, lives, timer, and restart controls."
```

Refine the current app:

```bash
python3 scripts/generate-game.py --refine "Make hazards easier to see and add a pause button."
```

The tool returns JSON containing the generated title, summary, review notes, and URL. Report those fields to the user and do not invent a URL.
