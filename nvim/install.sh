#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
STAMP="$(date +%Y%m%d_%H%M%S)"

usage() {
  cat <<'USAGE'
Usage: nvim/install.sh [--native] [--overwrite | --backup] [--yes]

  --native     Install native build deps (gcc/make/cmake/ninja/pkg-config + rust/cargo)
  --overwrite  Remove existing ~/.config/nvim before installing
  --backup     Move existing ~/.config/nvim to ~/.config/nvim.bak.<timestamp> before installing
  --yes        Non-interactive (fails if neither --overwrite nor --backup and config exists)

Default behavior:
  - If ~/.config/nvim does not exist: install
  - If it exists:
      * with --backup: backup then install
      * with --overwrite: delete then install
      * otherwise: abort (safe)
USAGE
}

NATIVE=0
MODE=""
YES=0

while [ $# -gt 0 ]; do
  case "$1" in
    --native) NATIVE=1 ;;
    --overwrite) MODE="overwrite" ;;
    --backup) MODE="backup" ;;
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
  case "$MODE" in
    backup)
      mv "$CONFIG_DIR" "${CONFIG_DIR}.bak.${STAMP}"
      ;;
    overwrite)
      rm -rf "$CONFIG_DIR"
      ;;
    "")
      if [ $YES -eq 1 ]; then
        echo "Refusing to continue: $CONFIG_DIR exists and no --backup/--overwrite provided." >&2
        exit 1
      else
        echo "Refusing to continue: $CONFIG_DIR exists. Use --backup or --overwrite." >&2
        exit 1
      fi
      ;;
  esac
fi

mkdir -p "$(dirname "$CONFIG_DIR")"
git clone https://github.com/LazyVim/starter "$CONFIG_DIR"
rm -rf "$CONFIG_DIR/.git"

rsync -a "$ROOT/overlay/" "$CONFIG_DIR/"

nvim --headless "+Lazy! sync" +qa
