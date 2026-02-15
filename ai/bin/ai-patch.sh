#!/usr/bin/env bash
set -euo pipefail

# Patch Surgery Workflow
# Three-phase flow:
#   Phase 1 — Patch Architecture (Claude, patch-architect role)
#   Phase 2 — Patch Emission (Codex, patcher role)
#   Phase 3 — Validation (ai-check --bundle patch)

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
AI_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Preflight ------------------------------------------------------------

command -v claude >/dev/null 2>&1 || {
  echo "error: claude not found. Run ./ai/deps.sh" >&2
  exit 1
}

command -v codex >/dev/null 2>&1 || {
  echo "error: codex not found. Run ./ai/deps.sh" >&2
  exit 1
}

# --- Parse arguments ------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "usage: ai-patch \"<task description>\"" >&2
  exit 1
fi

TASK="$1"

CLAUDE_FILE="$AI_DIR/CLAUDE.md"
CTX_DIR="$AI_DIR/context"
ARCHITECT_ROLE="$AI_DIR/roles/patch-architect.md"
PATCHER_ROLE="$AI_DIR/roles/patcher.md"

# Detect repo root
REPO_ROOT="$PWD"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi

# --- Phase 1: Patch Architecture (Claude) ---------------------------------

echo "═══ Phase 1: Patch Architecture ═══"
echo "Task: $TASK"
echo

ARCHITECT_PROMPT="$(
  echo "You are an AI assistant performing scoped change planning."
  echo "Follow the role definition exactly."
  echo
  echo "Repository root: $REPO_ROOT"
  echo

  echo "You are operating in PATCH-ARCHITECT mode."
  echo

  cat "$CLAUDE_FILE"
  echo

  for f in $(ls "$CTX_DIR"/*.md 2>/dev/null | LC_ALL=C sort); do
    cat "$f"
    echo
  done

  cat "$ARCHITECT_ROLE"

  if [[ -f "$REPO_ROOT/AGENTS.md" ]]; then
    echo
    echo "Repository context:"
    cat "$REPO_ROOT/AGENTS.md"
  fi
)"

# Capture architect plan output
ARCHITECT_PLAN="$(claude --system-prompt "$ARCHITECT_PROMPT" -p "Plan a patch for the following task. Output the files to modify, exact regions, and assertions for correctness:

$TASK" 2>&1)" || {
  echo "error: patch architecture phase failed" >&2
  exit 1
}

echo "$ARCHITECT_PLAN"

echo
echo "─── Review the plan above ───"
read -rp "Proceed to patch emission? [y/N] " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

# --- Phase 2: Patch Emission (Codex) --------------------------------------

echo
echo "═══ Phase 2: Patch Emission ═══"

PATCHER_PROMPT="$(
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

  cat "$PATCHER_ROLE"

  if [[ -f "$REPO_ROOT/AGENTS.md" ]]; then
    echo
    echo "Repository context:"
    cat "$REPO_ROOT/AGENTS.md"
  fi
)"

codex "$PATCHER_PROMPT

Architect plan:
$ARCHITECT_PLAN

Task: $TASK

Execute the architect plan above. Emit only unified diffs for the listed files."

# --- Phase 3: Validation -------------------------------------------------

echo
echo "═══ Phase 3: Validation ═══"

AI_CHECK="${SCRIPT_DIR}/ai-check.sh"
command -v ai-check >/dev/null 2>&1 && AI_CHECK="ai-check"
"$AI_CHECK" --bundle patch --fail-fast || {
  echo
  echo "✖ Patch validation failed. Review violations above." >&2
  exit 1
}

echo
echo "✔ Patch surgery complete."
