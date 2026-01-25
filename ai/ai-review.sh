#!/usr/bin/env bash
set -euo pipefail

command -v codex >/dev/null 2>&1 || {
  echo "codex not found. Run ./ai/deps.sh"
  exit 1
}

AI_DIR="$HOME/.config/ai"
ROLE_FILE="$AI_DIR/roles/reviewer.md"

PROMPT="$(
  echo "You are operating in REVIEWER mode."
  echo
  echo "GLOBAL RULE:"
  echo "You must NOT write or modify code."
  echo "You must NOT propose diffs or patches."
  echo "Explain issues, risks, and inconsistencies only."
  echo
  cat "$ROLE_FILE"
)"

codex "$PROMPT"

