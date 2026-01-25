#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -d "$REPO_ROOT/dotfiles/ai" ]]; then
  DOTFILES_DIR="$REPO_ROOT/dotfiles"
else
  DOTFILES_DIR="$REPO_ROOT"
fi

AI_SRC="$DOTFILES_DIR/ai"
AI_DST="$HOME/.config/ai"

mkdir -p "$AI_DST"
mkdir -p "$AI_DST/context"
mkdir -p "$AI_DST/roles"

copy() { rm -f "$2"; cp -f "$1" "$2"; }

# Install AI entrypoint scripts
for cmd in ai-chat.sh ai-plan.sh ai-review.sh ai-implement.sh; do
  SRC="$AI_SRC/$cmd"
  DST="$AI_DST/$cmd"

  if [[ -f "$SRC" ]]; then
    copy "$SRC" "$DST"
    chmod +x "$DST"
  fi
done

# Install ALL context files
for f in "$AI_SRC/context/"*.md; do
  [ -f "$f" ] || continue
  copy "$f" "$AI_DST/context/$(basename "$f")"
done

# Install role definitions
for role in architect planner reviewer implementer; do
  SRC="$AI_SRC/roles/$role.md"
  DST="$AI_DST/roles/$role.md"

  if [[ -f "$SRC" ]]; then
    copy "$SRC" "$DST"
  fi
done

