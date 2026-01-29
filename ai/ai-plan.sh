#!/usr/bin/env bash
set -euo pipefail

command -v codex >/dev/null 2>&1 || {
  echo "codex not found. Run ./ai/deps.sh"
  exit 1
}

AI_DIR="$HOME/.config/ai"
CTX_DIR="$AI_DIR/context"
ROLE_FILE="$AI_DIR/roles/planner.md"

PROMPT="$(
  echo "You are operating in PLANNER mode."
  echo
  echo "GLOBAL RULE:"
  echo "This is a READ-ONLY session."
  echo "You are NOT allowed to modify, rewrite, or summarize existing files."
  echo "You must describe changes abstractly as tasks or intentions."
  echo "Exception: You are allowed to apply changes and/or create new files if generating documentation or plans, and not source code."
  echo

  for f in $(ls "$CTX_DIR"/*.md 2>/dev/null | LC_ALL=C sort); do
    cat "$f"
    echo
  done

  cat "$ROLE_FILE"
)"

codex "$PROMPT"

