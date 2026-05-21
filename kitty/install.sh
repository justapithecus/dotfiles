#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KITTY_DIR="$HOME/.config/kitty"
mkdir -p "$KITTY_DIR"

cp -f "$DOTFILES_DIR/kitty.conf" "$KITTY_DIR/kitty.conf"
