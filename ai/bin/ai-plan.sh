#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
AI_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

command -v claude >/dev/null 2>&1 || {
  echo "claude not found. Run ./ai/deps.sh"
  exit 1
}

CLAUDE_FILE="$AI_DIR/CLAUDE.md"
CTX_DIR="$AI_DIR/context"
ROLE_FILE="$AI_DIR/roles/planner.md"

# Detect repo root (fallback to current dir)
REPO_ROOT="$PWD"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi

SYSTEM_PROMPT="$(
  echo "You are an AI assistant engaged in an interactive technical conversation."
  echo "Follow the role definition exactly."
  echo
  echo "Repository root: $REPO_ROOT"
  echo

  echo "You are operating in PLANNER mode."
  echo

  cat "$CLAUDE_FILE"
  echo

  for f in $(ls "$CTX_DIR"/*.md 2>/dev/null | LC_ALL=C sort); do
    cat "$f"
    echo
  done

  cat "$ROLE_FILE"

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

exec claude --system-prompt "$SYSTEM_PROMPT" "$@"
