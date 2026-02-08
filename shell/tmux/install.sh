#!/usr/bin/env bash
# shell/tmux/install.sh — install tmux config (XDG layout)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_DEST="$HOME/.config/tmux"

echo "  → Installing tmux config"
mkdir -p "$TMUX_DEST"

rm -f "$TMUX_DEST/tmux.conf"
cp -f "$SCRIPT_DIR/tmux.conf" "$TMUX_DEST/tmux.conf"

# Create local overrides placeholder if missing
if [[ ! -f "$TMUX_DEST/tmux.local.conf" ]]; then
  printf '# Local tmux overrides (not managed by dotfiles)\n' > "$TMUX_DEST/tmux.local.conf"
  echo "  → Created tmux.local.conf placeholder"
fi

echo "  ✔ tmux config installed"
