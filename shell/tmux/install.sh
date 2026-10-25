#!/usr/bin/env bash
# shell/tmux/install.sh — install tmux config (XDG layout)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_DEST="$HOME/.config/tmux"

echo "  → Installing tmux config"
mkdir -p "$TMUX_DEST"

# Keep a backup of any existing config that isn't already the managed one.
if [[ -f "$TMUX_DEST/tmux.conf" ]] && ! cmp -s "$SCRIPT_DIR/tmux.conf" "$TMUX_DEST/tmux.conf"; then
  backup="$TMUX_DEST/tmux.conf.bak.$(date +%Y%m%d_%H%M%S)"
  mv "$TMUX_DEST/tmux.conf" "$backup"
  echo "  → Backed up existing tmux.conf to $backup (move custom settings to tmux.local.conf)"
fi
rm -f "$TMUX_DEST/tmux.conf"
cp -f "$SCRIPT_DIR/tmux.conf" "$TMUX_DEST/tmux.conf"

# Create local overrides placeholder if missing
if [[ ! -f "$TMUX_DEST/tmux.local.conf" ]]; then
  printf '# Local tmux overrides (not managed by dotfiles)\n' > "$TMUX_DEST/tmux.local.conf"
  echo "  → Created tmux.local.conf placeholder"
fi

echo "  ✔ tmux config installed"
