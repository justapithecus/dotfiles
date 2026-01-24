#!/usr/bin/env bash
set -euo pipefail

# Standalone module installer (openSUSE Tumbleweed)
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$MODULE_DIR/.." && pwd)"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }

need zypper
need systemctl
need install
need ln
need mkdir
need chmod

# Root needed for zypper + /etc/geoclue
sudo -v

echo "▶ Installing packages"
sudo zypper -n install gammastep geoclue2

echo "▶ Installing gammastep config + hooks"
mkdir -p "$HOME/.config/gammastep/hooks"

ln -sf "$DOTFILES_DIR/gammastep/config.ini" \
  "$HOME/.config/gammastep/config.ini"

ln -sf "$DOTFILES_DIR/gammastep/hooks/99-evening-ramp.sh" \
  "$HOME/.config/gammastep/hooks/99-evening-ramp.sh"

chmod +x "$HOME/.config/gammastep/hooks/99-evening-ramp.sh"

echo "▶ Installing GeoClue drop-in allowlist"
sudo install -d -m 0755 /etc/geoclue/conf.d
sudo install -m 0644 \
  "$DOTFILES_DIR/gammastep/geoclue-conf.d/90-gammastep.conf" \
  /etc/geoclue/conf.d/90-gammastep.conf

# geoclue.service is commonly static / D-Bus activated; do not enable
sudo systemctl start geoclue.service 2>/dev/null || true
sudo systemctl restart geoclue.service 2>/dev/null || true

echo "▶ Installing gammastep user service (good login behavior)"
mkdir -p "$HOME/.config/systemd/user"

ln -sf "$DOTFILES_DIR/gammastep/systemd/gammastep.service" \
  "$HOME/.config/systemd/user/gammastep.service"

systemctl --user daemon-reload
systemctl --user enable --now gammastep.service

echo "▶ Done: gammastep enabled for user login"

