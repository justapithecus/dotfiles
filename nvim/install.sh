#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
SRC_DIR="$ROOT/overlay"
STARTER_URL="https://github.com/LazyVim/starter"

NATIVE=0
MODE="abort" # abort|backup|overwrite
YES=0

usage() {
  cat <<'USAGE'
Usage: nvim/install.sh [--native] [--backup|--overwrite] [--yes]

  --native     Install native build deps (gcc/make/cmake/ninja/pkg-config + rust/cargo)
  --backup     Move existing ~/.config/nvim to ~/.config/nvim.bak.<timestamp>
  --overwrite  Remove existing ~/.config/nvim before installing
  --yes        Non-interactive; fails unless --backup/--overwrite when config exists
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --native) NATIVE=1 ;;
    --backup) MODE="backup" ;;
    --overwrite) MODE="overwrite" ;;
    --yes) YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

mapfile -t BASE_PKGS < <(grep -vE '^\s*$|^\s*#' "$ROOT/pkgs/base.txt" || true)
PKGS=("${BASE_PKGS[@]}")

if [ $NATIVE -eq 1 ]; then
  mapfile -t NATIVE_PKGS < <(grep -vE '^\s*$|^\s*#' "$ROOT/pkgs/native-build.txt" || true)
  PKGS+=("${NATIVE_PKGS[@]}")
fi

sudo zypper -n refresh
sudo zypper -n in "${PKGS[@]}"

if [ -e "$CONFIG_DIR" ] || [ -L "$CONFIG_DIR" ]; then
  if [ "$MODE" = "backup" ]; then
    mv "$CONFIG_DIR" "${CONFIG_DIR}.bak.${STAMP}"
  elif [ "$MODE" = "overwrite" ]; then
    rm -rf "$CONFIG_DIR"
  else
    echo "Refusing: $CONFIG_DIR exists; use --backup or --overwrite." >&2
    exit 1
  fi
fi

mkdir -p "$(dirname "$CONFIG_DIR")"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 "$STARTER_URL" "$TMP/nvim"
rm -rf "$TMP/nvim/.git"

rsync -a --delete "$TMP/nvim/" "$CONFIG_DIR/"
rsync -a "$SRC_DIR/" "$CONFIG_DIR/"

nvim --headless "+Lazy! sync" +qa
