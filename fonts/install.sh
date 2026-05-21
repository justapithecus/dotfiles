#!/usr/bin/env bash
set -euo pipefail

OS="$(uname -s)"

if [[ "$OS" == "Linux" ]]; then
  sudo -v
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$DOTFILES_DIR/install-dm-mono-nerd.sh"
