#!/usr/bin/env bash
set -euo pipefail

sudo -v

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$DOTFILES_DIR/install-dm-mono-nerd.sh"

