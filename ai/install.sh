#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
DEST="${AI_BIN_DIR:-$HOME/.local/bin}"
COMP_DIR="${BASH_COMPLETION_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions}"

mkdir -p "$DEST"

for script in "$BIN_DIR"/ai-*.sh; do
  [ -f "$script" ] || continue
  name="$(basename "${script%.sh}")"
  cp -f "$script" "$DEST/$name"
  chmod +x "$DEST/$name"
done

# Install completion if available
if [[ -f "$SCRIPT_DIR/completion/ai.bash" ]]; then
  mkdir -p "$COMP_DIR"
  cp -f "$SCRIPT_DIR/completion/ai.bash" "$COMP_DIR/ai"
fi

echo "Installed to $DEST (copies)"
