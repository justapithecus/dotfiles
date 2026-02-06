#!/usr/bin/env bash
set -euo pipefail

# gastown installer
# Creates the gastown directory structure under ~/workspace.
# Idempotent — safe to run multiple times.

GASTOWN_HOME="${GASTOWN_HOME:-$HOME/workspace/gastown}"

dirs=(
  "$GASTOWN_HOME"
  "$GASTOWN_HOME/towns"
  "$GASTOWN_HOME/conversations"
  "$GASTOWN_HOME/fragments"
  "$GASTOWN_HOME/scratch"
)

for dir in "${dirs[@]}"; do
  if [[ -d "$dir" ]]; then
    echo "  exists  $dir"
  else
    mkdir -p "$dir"
    echo "  created $dir"
  fi
done

echo
echo "gastown is ready at $GASTOWN_HOME"
