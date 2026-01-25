#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

mkdir -p "$HOME/.config/zsh"
mkdir -p "$HOME/.config"

ZSHENV="$HOME/.zshenv"
ZDOT_LINE='export ZDOTDIR="$HOME/.config/zsh"'

if [[ ! -f "$ZSHENV" ]]; then
  echo "$ZDOT_LINE" > "$ZSHENV"
elif ! grep -Fxq "$ZDOT_LINE" "$ZSHENV"; then
  echo "$ZDOT_LINE" >> "$ZSHENV"
fi

copy() { rm -f "$2"; cp -f "$1" "$2"; }

copy "$DOTFILES_DIR/shell/zsh/.zshrc"          "$HOME/.config/zsh/.zshrc_custom"
copy "$DOTFILES_DIR/shell/zsh/env.zsh"         "$HOME/.config/zsh/env.zsh"
copy "$DOTFILES_DIR/shell/zsh/aliases.zsh"     "$HOME/.config/zsh/aliases.zsh"
copy "$DOTFILES_DIR/shell/zsh/completions.zsh" "$HOME/.config/zsh/completions.zsh"
copy "$DOTFILES_DIR/shell/zsh/keybindings.zsh" "$HOME/.config/zsh/keybindings.zsh"
copy "$DOTFILES_DIR/shell/starship.toml"       "$HOME/.config/starship.toml"

ZSHRC="$HOME/.zshrc"
CUSTOM_LINE='[[ -f "$HOME/.config/zsh/.zshrc_custom" ]] && source "$HOME/.config/zsh/.zshrc_custom"'

if [[ ! -f "$ZSHRC" ]]; then
  echo "$CUSTOM_LINE" > "$ZSHRC"
elif ! grep -Fxq "$CUSTOM_LINE" "$ZSHRC"; then
  printf '\n%s\n' "$CUSTOM_LINE" >> "$ZSHRC"
fi
