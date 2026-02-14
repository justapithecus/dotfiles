#!/usr/bin/env bash
set -euo pipefail

# Codex Review Script
# Purpose:
#   - Tactical code correctness review
#   - NOT structural validation
# Structural validation is handled by ai-skill.sh.

command -v codex >/dev/null 2>&1 || {
  echo "codex not found. Run ./ai/deps.sh"
  exit 1
}

AI_DIR="$HOME/.config/ai"
CLAUDE_FILE="$AI_DIR/CLAUDE.md"
REVIEW_ARCH="$AI_DIR/REVIEW_ARCHITECTURE.md"
CTX_DIR="$AI_DIR/context"
ROLE_FILE="$AI_DIR/roles/reviewer.md"

# Detect repo root (fallback to current dir)
REPO_ROOT="$PWD"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi

PROMPT="$(
  echo "You are an AI assistant engaged in an interactive technical conversation."
  echo "Follow the role definition exactly."
  echo
  echo "Repository root: $REPO_ROOT"
  echo

  echo "You are operating in REVIEWER mode."
  echo

  cat "$CLAUDE_FILE"
  echo

  for f in $(ls "$CTX_DIR"/*.md 2>/dev/null | LC_ALL=C sort); do
    cat "$f"
    echo
  done

  cat "$ROLE_FILE"

  if [[ -f "$REVIEW_ARCH" ]]; then
    echo
    echo "Review architecture:"
    cat "$REVIEW_ARCH"
  fi

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

codex "$PROMPT"
