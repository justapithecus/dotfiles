#!/usr/bin/env bash
set -euo pipefail

# gastown (gt) installer
# Ensures Go is available via mise, then installs the gt binary.
# Idempotent — safe to run multiple times.

GO_VERSION="1.25.6"

# --- Go via mise (global) ---

if ! command -v mise >/dev/null 2>&1; then
  echo "✖ mise is required but not found"
  exit 1
fi

# mise use -g is idempotent — installs if missing, sets global either way
echo "▶ Ensuring Go $GO_VERSION is set globally via mise"
mise use -g go@"$GO_VERSION"

# Ensure go is on PATH for this session
eval "$(mise activate bash --shims)"

# --- gastown (gt) via go install ---

echo "▶ Installing gastown (gt)"
go install github.com/steveyegge/gastown/cmd/gt@latest

if command -v gt >/dev/null 2>&1; then
  echo "  installed  $(gt --version 2>/dev/null || echo 'gt')"
else
  echo "  installed  gt to $(go env GOPATH)/bin/gt"
  echo "  note: ensure $(go env GOPATH)/bin is on your PATH"
fi

echo
echo "gastown is ready. Run 'gt install ~/gt --git' to create a workspace."
