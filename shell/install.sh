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
ZDOT_ZSHENV="$ZDOTDIR_PATH/.zshenv"
ZDOT_LINE='export ZDOTDIR="$HOME/.config/zsh"'
ZDOT_ZSHENV_LINE='[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"'
ZDOT_ENV_LINE='[[ -f "$ZDOTDIR/env.zsh" ]] && source "$ZDOTDIR/env.zsh"'
ZDOT_ZSHENV_CUSTOM_LINE='[[ -f "$ZDOTDIR/.zshenv_custom" ]] && source "$ZDOTDIR/.zshenv_custom"'

printf '%s\n%s\n' "$ZDOT_LINE" "$ZDOT_ZSHENV_LINE" > "$ZSHENV"
printf '%s\n%s\n' "$ZDOT_ENV_LINE" "$ZDOT_ZSHENV_CUSTOM_LINE" > "$ZDOT_ZSHENV"

touch "$ZDOTDIR_PATH/.zshrc_custom" "$ZDOTDIR_PATH/.zshenv_custom"
chmod 600 "$ZDOTDIR_PATH/.zshrc_custom" "$ZDOTDIR_PATH/.zshenv_custom"

if [[ ! -s "$ZDOTDIR_PATH/.zshrc_custom" ]]; then
  printf '# Local interactive-only overrides (aliases, prompt tweaks, etc.)\n' > "$ZDOTDIR_PATH/.zshrc_custom"
fi

if [[ ! -s "$ZDOTDIR_PATH/.zshenv_custom" ]]; then
  printf '# Local env exports for all zsh modes (tokens, host-specific vars)\n' > "$ZDOTDIR_PATH/.zshenv_custom"
fi

copy() { rm -f "$2"; cp -f "$1" "$2"; }

for filename in \
  keybindings.zsh \
  word-jump.zsh \
  env.zsh \
  aliases.zsh \
  completions.zsh \
  compdefs.zsh \
  .zshrc
do
  copy "$DOTFILES_DIR/shell/zsh/$filename" "$ZDOTDIR_PATH/$filename"
done

copy "$DOTFILES_DIR/shell/starship.toml"       "$HOME/.config/starship.toml"
