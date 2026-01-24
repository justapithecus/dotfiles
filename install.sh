#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Sudo keep-alive
# ----------------------------
echo "▶ Requesting sudo access"
sudo -v

# Keep sudo alive until script exits
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "▶ Dotfiles bootstrap starting..."

# ----------------------------
# Detect package manager
# ----------------------------
if command -v zypper >/dev/null 2>&1; then
  PM="zypper"
else
  echo "✖ Unsupported package manager"
  exit 1
fi

echo "▶ Using package manager: $PM"

# ----------------------------
# Install core packages
# ----------------------------
install_packages() {
  case "$PM" in
    zypper)
      sudo zypper refresh 
      sudo zypper install -y \
        zsh starship fzf bat eza ripgrep zoxide git-core \
	gammastep
      ;;
  esac
}

install_packages

# ----------------------------
# Create config dirs
# ----------------------------
echo "▶ Creating config directories"
mkdir -p ~/.config/{zsh,nvim,helix,konsole}

# ----------------------------
# Gammastep
# ----------------------------
echo "▶ Installing Gammastep hooks"

mkdir -p "$HOME/.config/gammastep/hooks"

ln -sf "$DOTFILES_DIR/gammastep/config.ini" "$HOME/.config/gammastep/config.ini"

ln -sf "$DOTFILES_DIR/gammastep/hooks/99-evening-ramp.sh" "$HOME/.config/gammastep/hooks/99-evening-ramp.sh"

chmod +x "$HOME/.config/gammastep/hooks/99-evening-ramp.sh"

# ----------------------------
# Configure ZDOTDIR (early)
# ----------------------------
ZSHENV="$HOME/.zshenv"
ZDOT_LINE='export ZDOTDIR="$HOME/.config/zsh"'

echo "▶ Ensuring ZDOTDIR is set via ~/.zshenv"

if [[ ! -f "$ZSHENV" ]]; then
  echo "$ZDOT_LINE" > "$ZSHENV"
elif ! grep -Fxq "$ZDOT_LINE" "$ZSHENV"; then
  echo "$ZDOT_LINE" >> "$ZSHENV"
fi

# ----------------------------
# Zsh (ZDOTDIR-based layout)
# ----------------------------
ZSH_DIR="$HOME/.config/zsh"
mkdir -p "$ZSH_DIR"

echo "▶ Configuring Zsh"

ln -sf "$DOTFILES_DIR/shell/zsh/.zshrc" "$ZSH_DIR/.zshrc"
ln -sf "$DOTFILES_DIR/shell/zsh/.zshrc_custom" "$ZSH_DIR/.zshrc_custom"
ln -sf "$DOTFILES_DIR/shell/zsh/env.zsh" "$ZSH_DIR/env.zsh"
ln -sf "$DOTFILES_DIR/shell/zsh/aliases.zsh" "$ZSH_DIR/aliases.zsh"
ln -sf "$DOTFILES_DIR/shell/zsh/completions.zsh" "$ZSH_DIR/completions.zsh"
ln -sf "$DOTFILES_DIR/shell/starship.toml" "$HOME/.config/starship.toml"

# ----------------------------
# Set default shell
# ----------------------------
if [[ "$SHELL" != *zsh ]]; then
  echo "▶ Setting zsh as default shell"
  chsh -s "$(command -v zsh)"
fi

ZSHRC="$HOME/.zshrc"
CUSTOM_LINE='[[ -f ~/.zshrc_custom ]] && source ~/.zshrc_custom'

if [[ ! -f "$ZSHRC" ]]; then
  echo "▶ Creating ~/.zshrc"
  echo "$CUSTOM_LINE" > "$ZSHRC"
elif ! grep -Fxq "$CUSTOM_LINE" "$ZSHRC"; then
  echo "▶ Injecting ~/.zshrc_custom into ~/.zshrc"
  echo "" >> "$ZSHRC"
  echo "$CUSTOM_LINE" >> "$ZSHRC"
fi

# ----------------------------
# fzf keybindings (optional but good)
# ----------------------------
if [[ -d /usr/share/fzf ]]; then
  echo "▶ Enabling fzf keybindings"
fi

# ----------------------------
# Workspace directory
# ----------------------------
echo "▶ Ensuring workspace directory exists"
mkdir -p "$HOME/workspace"

# ----------------------------
# Konsole (KDE Terminal)
# ----------------------------
echo "▶ Installing Konsole Profile"

KONSOLE_DIR="$HOME/.local/share/konsole"
mkdir -p "$KONSOLE_DIR"

# Profile (repo nested → flat install)
ln -sf "$DOTFILES_DIR/konsole/profiles/Dev.profile" \
  "$KONSOLE_DIR/Dev.profile"

# Color scheme (repo nested → flat install)
ln -sf "$DOTFILES_DIR/konsole/colorschemes/HighContrastDark.colorscheme" \
  "$KONSOLE_DIR/HighContrastDark.colorscheme"

# ----------------------------
# Final message
# ----------------------------
echo
echo "✔ Bootstrap complete"
echo "→ Restart your terminal or log out/in"

