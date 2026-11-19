#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KONSOLE_DIR="$HOME/.local/share/konsole"
mkdir -p "$KONSOLE_DIR"

cp -f "$DOTFILES_DIR/profiles/Dev.profile" \
  "$KONSOLE_DIR/Dev.profile"

cp -f "$DOTFILES_DIR/colorschemes/HighContrastDark.colorscheme" \
  "$KONSOLE_DIR/HighContrastDark.colorscheme"


