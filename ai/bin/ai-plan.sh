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

OUT_DIR="$AI_DIR/out"
mkdir -p "$OUT_DIR"

# Run session (no exec — script continues after)
claude --system-prompt "$SYSTEM_PROMPT" "$@" || true

# Detect plan.json written during session
PLAN_FILE="$OUT_DIR/plan.json"
if [[ -f "$PLAN_FILE" ]]; then
  echo
  echo "✔ plan.json detected at $PLAN_FILE"
  echo "  intent: $(jq -r '.intent // "unspecified"' "$PLAN_FILE" 2>/dev/null)"
  echo "  ai-implement will consume this automatically"
else
  echo
  echo "ℹ No plan.json written (optional — ai-implement will use diff-based mode detection)"
fi
