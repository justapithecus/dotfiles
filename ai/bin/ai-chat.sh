#!/usr/bin/env bash
set -euo pipefail

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

# Preflight
command -v claude >/dev/null 2>&1 || {
  echo "claude not found. Run ./ai/deps.sh"
  exit 1
}

CLAUDE_FILE="$AI_DIR/CLAUDE.md"
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

# Detect repo root (fallback to current dir)
REPO_ROOT="$PWD"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi

# Build system prompt
SYSTEM_PROMPT="$(
  echo "You are an AI assistant engaged in an interactive technical conversation."
  echo "Follow the role definition exactly."
  echo "Do not write code unless explicitly asked."
  echo
  echo "Repository root: $REPO_ROOT"
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

  # Repo-declared context layers (orientation, contracts, etc.).
  # The repo populates .ai/context/*.md to declare its own spine.
  for f in $(ls "$REPO_ROOT/.ai/context"/*.md 2>/dev/null | LC_ALL=C sort); do
    echo
    echo "Repo-declared context ($(basename "$f")):"
    cat "$f"
  done
)"

# Start interactive Claude session
exec claude --system-prompt "$SYSTEM_PROMPT" "$@"
