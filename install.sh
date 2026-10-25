#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--terminal=ghostty|kitty|konsole|none]

  --terminal=NAME  Terminal config to install. Also settable with
                   DOTFILES_TERMINAL=NAME. Default: auto-detect
                   (Linux: konsole; macOS: ghostty, else kitty).
USAGE
}

TERMINAL_CHOICE="${DOTFILES_TERMINAL:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --terminal=*) TERMINAL_CHOICE="${1#*=}" ;;
    --terminal)   shift; TERMINAL_CHOICE="${1:-}" ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

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
    # No Homebrew, Xcode Command Line Tools, or conda: every tool comes
    # from mise as a prebuilt binary in $HOME. Nothing here compiles code.
    PM="mise"
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
    mise)
      export PATH="$HOME/.local/bin:$PATH"
      if ! command -v mise >/dev/null 2>&1; then
        echo "▶ Installing mise to ~/.local/bin"
        curl -fsSL https://mise.run | sh
      fi
      # git: GitHub Desktop's relocatable build (links only macOS system
      # libraries). It must be told where its helpers live, so point
      # GIT_EXEC_PATH at mise's "latest" link; mise applies [env] to shims.
      case "$(uname -m)" in
        arm64)  GIT_ASSET="*-macOS-arm64.tar.gz" ;;
        x86_64) GIT_ASSET="*-macOS-x64.tar.gz" ;;
      esac
      GIT_DIR_MISE="${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs/github-desktop-dugite-native/latest"

      # Writes ~/.config/mise/config.toml so the tools are global.
      mise use -g -y \
        starship fzf bat eza ripgrep zoxide \
        node tmux yq gh \
        "github:desktop/dugite-native[asset_pattern=$GIT_ASSET,bin_path=bin]"
      mise set -g \
        GIT_EXEC_PATH="$GIT_DIR_MISE/libexec/git-core" \
        GIT_TEMPLATE_DIR="$GIT_DIR_MISE/share/git-core/templates"
      # Re-runs bump every tool to its newest release.
      mise upgrade -y
      ;;
  esac
}

install_packages

# ----------------------------
# Create config dirs
# ----------------------------
echo "▶ Creating config directories"
mkdir -p ~/.config/{zsh,nvim,starship}

# ----------------------------
# Zsh (ZDOTDIR-based layout)
# ----------------------------
bash "$DOTFILES_DIR/shell/install.sh"

# ----------------------------
# Tmux
# ----------------------------
echo "▶ Installing Tmux config"
bash "$DOTFILES_DIR/shell/tmux/install.sh"

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
# Pick one with --terminal / DOTFILES_TERMINAL, or let it auto-detect.
# To switch later, run that terminal's installer on its own,
# e.g. `bash kitty/install.sh` or `bash ghostty/install.sh`.
detect_terminal() {
  if [[ "$OS" == "Linux" ]]; then
    echo konsole
  elif [[ -d /Applications/Ghostty.app || -d "$HOME/Applications/Ghostty.app" ]] \
       || command -v ghostty >/dev/null 2>&1; then
    echo ghostty
  elif [[ -d /Applications/kitty.app || -d "$HOME/Applications/kitty.app" ]] \
       || command -v kitty >/dev/null 2>&1; then
    echo kitty
  else
    echo ghostty
  fi
}

TERMINAL_CHOICE="${TERMINAL_CHOICE:-$(detect_terminal)}"
case "$TERMINAL_CHOICE" in
  ghostty|kitty|konsole)
    echo "▶ Installing $TERMINAL_CHOICE config"
    bash "$DOTFILES_DIR/$TERMINAL_CHOICE/install.sh"
    ;;
  none)
    echo "▶ Skipping terminal config"
    ;;
  *)
    echo "✖ Unknown terminal: $TERMINAL_CHOICE (expected ghostty, kitty, konsole, none)" >&2
    exit 2
    ;;
esac

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
# Voice input
# ----------------------------
echo "▶ Installing Voice input"
bash "$DOTFILES_DIR/voice/install.sh"

# ----------------------------
# Final message
# ----------------------------
echo
echo "✔ Bootstrap complete"
echo "→ Restart your terminal or log out/in"
