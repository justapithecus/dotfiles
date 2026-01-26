#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Sudo keep-alive
# ----------------------------
echo "▶ Requesting sudo access"
sudo -v

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
      sudo wget https://mise.jdx.dev/rpm/mise.repo -O /etc/zypp/repos.d/mise.repo
      sudo zypper refresh
      sudo zypper install -y \
        zsh starship fzf bat eza ripgrep zoxide git-core mise \
        nodejs
      ;;
  esac
}

install_packages

# ----------------------------
# Create config dirs
# ----------------------------
echo "▶ Creating config directories"
mkdir -p ~/.config/{zsh,nvim,helix,konsole,starship}

# ----------------------------
# Zsh (ZDOTDIR-based layout)
# ----------------------------
bash "$DOTFILES_DIR/shell/install.sh"

# ----------------------------
# Set default shell
# ----------------------------
if [[ "$SHELL" != *zsh ]]; then
  echo "▶ Setting zsh as default shell"
  chsh -s "$(command -v zsh)"
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
# Fonts
# ----------------------------
echo "▶ Installing Fonts"
bash "$DOTFILES_DIR/fonts/install.sh"

# ----------------------------
# Konsole (KDE Terminal)
# ----------------------------
echo "▶ Installing Konsole Profile"
bash "$DOTFILES_DIR/konsole/install.sh"

# ----------------------------
# Git Config defaults
# ----------------------------
git config --global push.autoSetupRemote true

# ----------------------------
# Neovim (LazyVim)
# ----------------------------
echo "▶ Installing Neovim (LazyVim)"
bash "$DOTFILES_DIR/nvim/install.sh" --backup --native --yes

# ----------------------------
# AI Tooling 
# ----------------------------
echo "▶ Installing AI Tooling"
bash "$DOTFILES_DIR/ai/install.sh"

# ----------------------------
# Final message
# ----------------------------
echo
echo "✔ Bootstrap complete"
echo "→ Restart your terminal or log out/in"
