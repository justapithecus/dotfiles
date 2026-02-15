#!/usr/bin/env bash
set -euo pipefail

# Patch Entrypoint (Codex)
# Purpose:
#   - Emit minimal unified diffs from a patch-architect plan
#   - NOT structural validation, NOT code review
# Structural validation: ai-skill.sh
# Code review: ai-review.sh

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
AI_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

command -v codex >/dev/null 2>&1 || {
  echo "codex not found. Run ./ai/deps.sh"
  exit 1
}

CLAUDE_FILE="$AI_DIR/CLAUDE.md"
CTX_DIR="$AI_DIR/context"
ROLE_FILE="$AI_DIR/roles/patcher.md"

# Detect repo root (fallback to current dir)
REPO_ROOT="$PWD"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi

PROMPT="$(
  echo "You are an AI assistant performing minimal patch emission."
  echo "Follow the role definition exactly."
  echo
  echo "Repository root: $REPO_ROOT"
  echo

  echo "You are operating in PATCHER mode."
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
)"

codex "$PROMPT"
