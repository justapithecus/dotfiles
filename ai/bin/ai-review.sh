#!/usr/bin/env bash
set -euo pipefail

# Codex Review Script
# Purpose:
#   - Tactical code correctness review
#   - NOT structural validation
# Structural validation is handled by ai-skill.sh.

# Portable script directory resolution (no readlink -f dependency)
SCRIPT_DIR="$(
  src="${BASH_SOURCE[0]}"
  while [[ -L "$src" ]]; do
    dir="$(cd "$(dirname "$src")" && pwd -P)"
    src="$(readlink "$src")"
    [[ "$src" != /* ]] && src="$dir/$src"
  done
  cd "$(dirname "$src")" && pwd -P
)"

# Resolve AI_DIR: env override > repo-relative parent > install breadcrumb
if [[ -n "${AI_DIR:-}" ]] && [[ -f "$AI_DIR/CLAUDE.md" ]]; then
  : # caller-provided AI_DIR
elif [[ -f "$SCRIPT_DIR/../CLAUDE.md" ]]; then
  AI_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [[ -f "$SCRIPT_DIR/.ai-source" ]]; then
  AI_DIR="$(cat "$SCRIPT_DIR/.ai-source")"
else
  echo "error: cannot locate ai/ directory. Set AI_DIR or reinstall." >&2
  exit 1
fi

command -v codex >/dev/null 2>&1 || {
  echo "codex not found. Run ./ai/deps.sh"
  exit 1
}

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

  while IFS= read -r -d '' f; do
    cat "$f"
    echo
  done < <(find "$CTX_DIR" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null | LC_ALL=C sort -z)

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

  # Repo-declared context layers (orientation, contracts, etc.).
  # The repo populates .ai/context/*.md to declare its own spine.
  while IFS= read -r -d '' f; do
    echo
    echo "Repo-declared context ($(basename "$f")):"
    cat "$f"
  done < <(find "$REPO_ROOT/.ai/context" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null | LC_ALL=C sort -z)
)"

codex "$PROMPT"
