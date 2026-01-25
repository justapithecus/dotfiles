#!/usr/bin/env bash
set -euo pipefail

command -v claude >/dev/null || { echo "claude not found"; exit 1; }

AI_DIR="$HOME/.config/ai"
CTX_DIR="$AI_DIR/context"
ROLE_DIR="$AI_DIR/roles"

# Build system prompt from context + role
SYSTEM_PROMPT="$(
  for f in "$CTX_DIR"/*.md; do
    [ -f "$f" ] || continue
    cat "$f"
    echo
  done
  cat "$ROLE_DIR/implementer.md"
)"

# Interactive session, not one-shot
exec claude --system-prompt "$SYSTEM_PROMPT" "$@"

