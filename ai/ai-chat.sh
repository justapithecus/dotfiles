#!/usr/bin/env bash
set -euo pipefail

# Preflight
command -v codex >/dev/null 2>&1 || {
  echo "codex not found. Run ./ai/deps.sh"
  exit 1
}

AI_DIR="$HOME/.config/ai"
CTX_DIR="$AI_DIR/context"
ROLES_DIR="$AI_DIR/roles"

ROLE="architect"
if [[ $# -ge 1 ]]; then
  ROLE="$1"
fi

ROLE_FILE="$ROLES_DIR/$ROLE.md"

if [[ ! -f "$ROLE_FILE" ]]; then
  echo "Unknown role: $ROLE"
  echo "Available roles:"
  ls "$ROLES_DIR" | sed 's/\.md$//' | sed 's/^/  - /'
  exit 1
fi

# Detect repo root (optional)
REPO_ROOT=""
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi

# Build initial prompt
PROMPT="$(
  echo "You are an AI assistant engaged in an interactive technical conversation."
  echo "Follow the role definition exactly."
  echo "Do not write code unless explicitly asked."
  echo

  for f in $(ls "$CTX_DIR"/*.md 2>/dev/null | LC_ALL=C sort); do
    cat "$f"
    echo
  done

  cat "$ROLE_FILE"

  if [[ -n "$REPO_ROOT" && -f "$REPO_ROOT/AGENTS.md" ]]; then
    echo
    echo "Repository context:"
    cat "$REPO_ROOT/AGENTS.md"
  fi
)"

# Start interactive Codex session
codex "$PROMPT"

