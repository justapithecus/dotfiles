#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# Claude Code (primary — chat, plan, implement)
# ==========================================================

if ! command -v claude >/dev/null 2>&1; then
  echo "Installing Claude Code…"
  curl -fsSL https://claude.ai/install.sh | sh
else
  echo "Claude Code already installed"
fi

# ==========================================================
# Codex CLI (optional — reviewer only)
# ==========================================================

if ! command -v codex >/dev/null 2>&1; then
  echo "Installing Codex CLI (user-local)…"

  if ! command -v npm >/dev/null 2>&1; then
    echo "npm not found; skipping Codex install"
  else
    npm install --prefix "$HOME/.local" -g @openai/codex
  fi
else
  echo "Codex CLI already installed"
fi

