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

# mise's GitHub backend reads GITHUB_TOKEN; fall back to the gh CLI's login,
# through mise when gh is a mise tool whose shims are not yet on PATH.
if [[ -z "${GITHUB_TOKEN:-}${MISE_GITHUB_TOKEN:-}" ]]; then
  GITHUB_TOKEN="$(gh auth token 2>/dev/null || mise exec -- gh auth token 2>/dev/null || true)"
  [[ -n "$GITHUB_TOKEN" ]] && export GITHUB_TOKEN || unset GITHUB_TOKEN
fi

# Global on purpose: a repository mise.toml pin would make every clone of this
# public repository fetch a private release, and Bosun's agent hooks run in
# every repository, not just this one.
echo "▶ Installing Bosun $BOSUN_VERSION via mise (global)"
if ! mise use -g -y "github:pithecene/bosun@$BOSUN_VERSION"; then
  echo "✖ Could not install Bosun. Set GITHUB_TOKEN, or log in with 'gh auth login'," >&2
  echo "  with a token that can read pithecene/bosun." >&2
  exit 1
fi

echo "  installed  $(mise exec -- bosun --version 2>/dev/null || echo "bosun $BOSUN_VERSION")"
