#!/usr/bin/env bash
set -euo pipefail

OS="$(uname -s)"

if [[ "$OS" == "Linux" ]]; then
  sudo -v
  FONT_DIR="$HOME/.local/share/fonts/dm-mono-nerd"
elif [[ "$OS" == "Darwin" ]]; then
  FONT_DIR="$HOME/Library/Fonts"
else
  echo "✖ Unsupported OS: $OS" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

git clone --depth=1 https://github.com/minhuw/dm-mono-nerd-font.git "$TMP_DIR/dm-mono-nerd-font"

mkdir -p "$FONT_DIR"
cp "$TMP_DIR"/dm-mono-nerd-font/dm-mono-nerd-font/*.ttf "$FONT_DIR/"

if [[ "$OS" == "Linux" ]]; then
  fc-cache -fv "$HOME/.local/share/fonts"
fi
