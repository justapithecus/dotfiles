#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ghostty reads $XDG_CONFIG_HOME/ghostty/config.ghostty on every platform.
GHOSTTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
mkdir -p "$GHOSTTY_DIR"

cp -f "$DOTFILES_DIR/config.ghostty" "$GHOSTTY_DIR/config.ghostty"

# On macOS Ghostty also reads a config in Application Support, loaded after
# the XDG one, so anything there overrides these settings.
APP_SUPPORT_CFG="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
if [[ -s "$APP_SUPPORT_CFG" ]]; then
  echo "⚠ $APP_SUPPORT_CFG is not empty and overrides $GHOSTTY_DIR/config.ghostty"
fi

echo "✔ Ghostty config installed (reload in Ghostty with Cmd+Shift+,)"
