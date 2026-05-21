#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "▶ Dotfiles bootstrap starting..."

# ----------------------------
# Detect OS and package manager
# ----------------------------
case "$OS" in
  Linux)
    if command -v zypper >/dev/null 2>&1; then
      PM="zypper"
    else
      echo "✖ Unsupported Linux package manager (zypper required)"
      exit 1
    fi
    ;;
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      PM="brew"
    else
      echo "✖ Homebrew not found — install from https://brew.sh"
      exit 1
    fi
    ;;
  *)
    echo "✖ Unsupported OS: $OS"
    exit 1
    ;;
esac

echo "▶ Using package manager: $PM"

# ----------------------------
# Sudo keep-alive (Linux only)
# ----------------------------
if [[ "$OS" == "Linux" ]]; then
  echo "▶ Requesting sudo access"
  sudo -v

  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
fi

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
        nodejs tmux yq
      ;;
    brew)
      brew install \
        starship fzf bat eza ripgrep zoxide git mise \
        node tmux yq gh
      ;;
  esac
}

install_packages

# ----------------------------
# Create config dirs
# ----------------------------
echo "▶ Creating config directories"
mkdir -p ~/.config/{zsh,nvim,helix,starship}

# ----------------------------
# Zsh (ZDOTDIR-based layout)
# ----------------------------
bash "$DOTFILES_DIR/shell/install.sh"

# ----------------------------
# Set default shell (Linux only — macOS defaults to zsh)
# ----------------------------
if [[ "$OS" == "Linux" && "$SHELL" != *zsh ]]; then
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
# Terminal (platform-specific)
# ----------------------------
if [[ "$OS" == "Linux" ]]; then
  echo "▶ Installing Konsole Profile"
  bash "$DOTFILES_DIR/konsole/install.sh"
elif [[ "$OS" == "Darwin" ]]; then
  echo "▶ Installing Kitty Config"
  bash "$DOTFILES_DIR/kitty/install.sh"
fi

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
