#!/usr/bin/env bash
set -euo pipefail

# konsole-session installer (openSUSE Tumbleweed, KDE Plasma 6)
# Copies the script and its login unit into place and enables the unit.
# Idempotent — safe to run multiple times.

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
UNIT="konsole-session-restore.service"

if [[ "$(uname -s)" != "Linux" ]] || ! command -v zypper >/dev/null 2>&1; then
  echo "✖ konsole-session is openSUSE-specific (zypper not found)"
  exit 1
fi

missing=()
for dep in konsole qdbus6 kreadconfig6 systemctl systemd-run journalctl /usr/bin/python3; do
  command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
done
if (( ${#missing[@]} )); then
  echo "✖ missing: ${missing[*]}"
  echo "  sudo zypper install konsole qt6-tools-qdbus kf6-kconfig python3"
  exit 1
fi

echo "▶ Installing konsole-session"
mkdir -p "$BIN_DIR" "$UNIT_DIR"
install -m 0755 "$TOOL_DIR/konsole-session" "$BIN_DIR/konsole-session"
install -m 0644 "$TOOL_DIR/$UNIT" "$UNIT_DIR/$UNIT"

# Re-enable so a changed [Install] section replaces any previous wants link.
systemctl --user disable "$UNIT" >/dev/null 2>&1 || true
systemctl --user daemon-reload
systemctl --user enable "$UNIT"

echo "  installed  $BIN_DIR/konsole-session"
echo "  enabled    $UNIT"
echo
echo "Run 'konsole-session save' right before restarting; windows come back at the next login."
