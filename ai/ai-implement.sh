#!/usr/bin/env bash
set -euo pipefail

command -v claude >/dev/null || { echo "claude not found"; exit 1; }

AI_DIR="$HOME/.config/ai"
CLAUDE_FILE="$AI_DIR/CLAUDE.md"
CTX_DIR="$AI_DIR/context"
ROLE_DIR="$AI_DIR/roles"

# Detect repo root (fallback to current dir)
REPO_ROOT="$PWD"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi

# Build system prompt from context + role
SYSTEM_PROMPT="$(
  echo "You are an AI assistant engaged in an interactive technical conversation."
  echo "Follow the role definition exactly."
  echo
  echo "Repository root: $REPO_ROOT"
  echo

  echo "You are operating in IMPLEMENTER mode."
  echo

  if [[ -f "$CLAUDE_FILE" ]]; then
    cat "$CLAUDE_FILE"
    echo
  fi

  for f in $(ls "$CTX_DIR"/*.md 2>/dev/null | LC_ALL=C sort); do
    cat "$f"
    echo
  done
  cat "$ROLE_DIR/implementer.md"

  if [[ -f "$REPO_ROOT/AGENTS.md" ]]; then
    echo
    echo "Repository context:"
    cat "$REPO_ROOT/AGENTS.md"
  fi

  if [[ -f "$REPO_ROOT/docs/ARCH_INDEX.md" ]]; then
    echo
    echo "Repository architecture index:"
    cat "$REPO_ROOT/docs/ARCH_INDEX.md"
  fi
)"

# Interactive session, not one-shot
exec claude --system-prompt "$SYSTEM_PROMPT" "$@"
