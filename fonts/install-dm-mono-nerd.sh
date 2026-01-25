#!/usr/bin/env bash
set -euo pipefail

sudo -v

FONT_DIR="$HOME/.local/share/fonts/dm-mono-nerd"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

git clone --depth=1 https://github.com/minhuw/dm-mono-nerd-font.git "$TMP_DIR/dm-mono-nerd-font"

mkdir -p "$FONT_DIR"
cp "$TMP_DIR"/dm-mono-nerd-font/dm-mono-nerd-font/*.ttf "$FONT_DIR/"

fc-cache -fv "$HOME/.local/share/fonts"

