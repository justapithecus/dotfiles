#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

if [[ -d "$repo_root/dotfiles" ]] && [[ -d "$repo_root/dotfiles/ai" ]]; then
  DOTFILES_DIR="$repo_root/dotfiles"
else
  DOTFILES_DIR="$repo_root"
fi

AI_BIN="$HOME/.config/ai/bin"
mkdir -p "$AI_BIN"

copy() { rm -f "$2"; cp -f "$1" "$2"; }

for cmd in ai-chat ai-plan ai-review ai-implement; do
  src="$DOTFILES_DIR/scripts/$cmd"
  dst="$AI_BIN/$cmd"

  if [[ -f "$src" ]]; then
    copy "$src" "$dst"
  fi
done

