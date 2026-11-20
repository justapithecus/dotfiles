#!/usr/bin/env bash
# bosun/install.sh — install Bosun, the development-process runner
# https://github.com/pithecene/bosun (private)
#
# Opt-in only: the top-level install.sh runs this script only with
# --with-bosun or DOTFILES_BOSUN=1. Releases come from a private repository,
# so the GitHub token must be able to read pithecene/bosun.
# Idempotent — safe to run multiple times.
set -euo pipefail

BOSUN_VERSION="0.26.5"

command -v mise >/dev/null 2>&1 || { echo "✖ mise required (installed by the top-level install.sh)" >&2; exit 1; }

# mise's GitHub backend reads GITHUB_TOKEN; fall back to the gh CLI's login.
if [[ -z "${GITHUB_TOKEN:-}${MISE_GITHUB_TOKEN:-}" ]] && command -v gh >/dev/null 2>&1; then
  GITHUB_TOKEN="$(gh auth token 2>/dev/null || true)"
  [[ -n "$GITHUB_TOKEN" ]] && export GITHUB_TOKEN
fi

echo "▶ Installing Bosun $BOSUN_VERSION via mise (global)"
if ! mise use -g -y "github:pithecene/bosun@$BOSUN_VERSION"; then
  echo "✖ Could not install Bosun. The GitHub token must be able to read pithecene/bosun." >&2
  exit 1
fi

echo "  installed  $(mise exec -- bosun --version 2>/dev/null || echo "bosun $BOSUN_VERSION")"
