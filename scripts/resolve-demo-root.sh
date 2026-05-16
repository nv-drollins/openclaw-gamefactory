#!/usr/bin/env bash

resolve_demo_root() {
  local script_dir="${1:?missing script directory}"
  local default_root override root

  default_root="$(cd "$script_dir/.." && pwd)"
  override="${OPENCLAW_GAMEFACTORY_DEMO_ROOT:-}"

  if [ -n "$override" ]; then
    root="$(cd "$override" 2>/dev/null && pwd || printf '%s' "$override")"
    if [ -f "$root/server.py" ] && [ -f "$root/skills/game-factory/SKILL.md" ]; then
      printf '%s\n' "$root"
      return 0
    fi

    echo "Ignoring OPENCLAW_GAMEFACTORY_DEMO_ROOT=$override; it does not look like a valid demo checkout." >&2
  fi

  printf '%s\n' "$default_root"
}
