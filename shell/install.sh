#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

if [[ -d "$repo_root/dotfiles" ]] && [[ -f "$repo_root/dotfiles/shell/zsh/.zshrc" ]]; then
  DOTFILES_DIR="$repo_root/dotfiles"
else
  DOTFILES_DIR="$repo_root"
fi

ZDOTDIR_PATH="$HOME/.config/zsh"
mkdir -p "$ZDOTDIR_PATH"
mkdir -p "$HOME/.config"

ZSHENV="$HOME/.zshenv"
ZDOT_LINE='export ZDOTDIR="$HOME/.config/zsh"'
ZSHENV_CUSTOM_LINE='[[ -f "$HOME/.config/zsh/.zshenv_custom" ]] && source "$HOME/.config/zsh/.zshenv_custom"'

if [[ ! -f "$ZSHENV" ]]; then
  printf '%s\n' "$ZDOT_LINE" > "$ZSHENV"
elif ! grep -Fxq "$ZDOT_LINE" "$ZSHENV"; then
  printf '\n%s\n' "$ZDOT_LINE" >> "$ZSHENV"
fi

if ! grep -Fxq "$ZSHENV_CUSTOM_LINE" "$ZSHENV"; then
  printf '\n%s\n' "$ZSHENV_CUSTOM_LINE" >> "$ZSHENV"
fi

touch "$ZDOTDIR_PATH/.zprofile" "$ZDOTDIR_PATH/.zlogin" "$ZDOTDIR_PATH/.zshrc_custom" "$ZDOTDIR_PATH/.zshenv_custom"

copy() { rm -f "$2"; cp -f "$1" "$2"; }

copy "$DOTFILES_DIR/shell/zsh/keybindings.zsh" "$ZDOTDIR_PATH/keybindings.zsh"
copy "$DOTFILES_DIR/shell/zsh/word-jump.zsh"   "$ZDOTDIR_PATH/word-jump.zsh"
copy "$DOTFILES_DIR/shell/zsh/env.zsh"         "$ZDOTDIR_PATH/env.zsh"
copy "$DOTFILES_DIR/shell/zsh/aliases.zsh"     "$ZDOTDIR_PATH/aliases.zsh"
copy "$DOTFILES_DIR/shell/zsh/completions.zsh" "$ZDOTDIR_PATH/completions.zsh"
copy "$DOTFILES_DIR/shell/zsh/compdefs.zsh"    "$ZDOTDIR_PATH/compdefs.zsh"
copy "$DOTFILES_DIR/shell/zsh/.zshrc"          "$ZDOTDIR_PATH/.zshrc"

copy "$DOTFILES_DIR/shell/starship.toml"       "$HOME/.config/starship.toml"
