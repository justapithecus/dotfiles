#!/usr/bin/env bash
# voice/install.sh — install Handy, offline push-to-talk speech-to-text
# https://github.com/cjpais/Handy
#
# Handy records, transcribes locally (Parakeet/Whisper/Moonshine via its own
# engine) and pastes into the focused app, so no whisper.cpp, recorder, or
# shell/tmux keybindings are needed. Always installs the latest release.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
ARCH="$(uname -m)"
REPO="cjpais/Handy"

# Developer ID team that signs Handy for macOS; refuse anything else.
HANDY_TEAM_ID="UWFLB4GC25"

command -v yq >/dev/null 2>&1 || { echo "✖ yq required (installed by the top-level install.sh)" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" -o "$TMP/release.json"
VERSION="$(yq -p json -o yaml '.tag_name' "$TMP/release.json")"
VERSION="${VERSION#v}"

# Download the release asset whose name matches $1 and verify it against the
# SHA-256 digest GitHub publishes for it. Prints the downloaded path.
fetch_asset() {
  local pattern="$1" name url digest file actual
  name="$(yq -p json -o yaml ".assets[] | select(.name | test(\"$pattern\")) | .name" "$TMP/release.json" | head -1)"
  [[ -n "$name" ]] || { echo "✖ No Handy $VERSION asset matching $pattern" >&2; exit 1; }
  url="$(yq -p json -o yaml ".assets[] | select(.name == \"$name\") | .browser_download_url" "$TMP/release.json")"
  digest="$(yq -p json -o yaml ".assets[] | select(.name == \"$name\") | .digest" "$TMP/release.json")"
  file="$TMP/$name"
  curl -fsSL "$url" -o "$file"
  if command -v sha256sum >/dev/null 2>&1; then
    actual="sha256:$(sha256sum "$file" | cut -d' ' -f1)"
  else
    actual="sha256:$(shasum -a 256 "$file" | cut -d' ' -f1)"
  fi
  [[ "$actual" == "$digest" ]] || { echo "✖ Checksum mismatch for $name" >&2; exit 1; }
  echo "$file"
}

install_macos() {
  # /Applications needs an admin account; fall back to ~/Applications.
  local app_dir="/Applications" current="" dmg
  if [[ ! -w "$app_dir" ]]; then
    app_dir="$HOME/Applications"
    mkdir -p "$app_dir"
  fi
  local app="$app_dir/Handy.app"
  if [[ -d "$app" ]]; then
    current="$(defaults read "$app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || true)"
  fi
  if [[ "$current" == "$VERSION" ]]; then
    echo "  ✔ Handy $VERSION already installed"
    return
  fi

  case "$ARCH" in
    arm64)  dmg="$(fetch_asset '_aarch64\.dmg$')" ;;
    x86_64) dmg="$(fetch_asset '_x64\.dmg$')" ;;
    *) echo "✖ Unsupported macOS arch: $ARCH" >&2; exit 1 ;;
  esac

  MNT="$TMP/mnt"
  mkdir -p "$MNT"
  hdiutil attach -nobrowse -readonly -mountpoint "$MNT" "$dmg" >/dev/null
  trap 'hdiutil detach "$MNT" >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT

  # Signature must be valid, notarized, and from Handy's own developer team.
  codesign --verify --deep --strict "$MNT/Handy.app"
  spctl --assess --type execute "$MNT/Handy.app"
  local sig
  sig="$(codesign -dv "$MNT/Handy.app" 2>&1)"
  [[ $'\n'"$sig"$'\n' == *$'\n'"TeamIdentifier=$HANDY_TEAM_ID"$'\n'* ]] \
    || { echo "✖ Handy.app is not signed by team $HANDY_TEAM_ID" >&2; exit 1; }

  # Copy next to the existing app first, so a failed copy leaves the old
  # install untouched; then swap.
  local staged="$app.new" old="$app.old"
  rm -rf "$staged" "$old"
  ditto "$MNT/Handy.app" "$staged"

  osascript -e 'quit app "Handy"' >/dev/null 2>&1 || true
  if [[ -d "$app" ]]; then mv "$app" "$old"; fi
  mv "$staged" "$app"
  rm -rf "$old"
  echo "  ✔ Handy $VERSION installed to $app"
}

install_linux() {
  local rpm
  case "$ARCH" in
    x86_64)  rpm="$(fetch_asset 'x86_64\.rpm$')" ;;
    aarch64) rpm="$(fetch_asset 'aarch64\.rpm$')" ;;
    *) echo "✖ Unsupported Linux arch: $ARCH" >&2; exit 1 ;;
  esac

  # The RPM itself is unsigned; its checksum was verified above.
  sudo zypper -n install --allow-unsigned-rpm "$rpm"

  # Runtime library Handy links against, plus a Wayland text-input helper.
  sudo zypper -n install libgtk-layer-shell0 \
    || sudo zypper -n install gtk-layer-shell \
    || echo "⚠ Could not install gtk-layer-shell; Handy may fail to start"
  sudo zypper -n install wtype \
    || echo "⚠ Could not install wtype; Handy will fall back to its built-in input"

  # Handy can't register global shortcuts on Wayland, so bind one in KDE.
  local kde_dir="$HOME/.local/share/kglobalaccel"
  mkdir -p "$kde_dir"
  cp -f "$SCRIPT_DIR/kde/handy-toggle.desktop" "$kde_dir/handy-toggle.desktop"
  echo "  ✔ Handy $VERSION installed (KDE shortcut: Meta+Shift+V)"
}

case "$OS" in
  Darwin) install_macos ;;
  Linux)  install_linux ;;
  *) echo "✖ Unsupported OS: $OS" >&2; exit 1 ;;
esac

cat <<'EOF'
  → First launch: pick "Parakeet TDT 0.6B v2" (English) or
    "Parakeet TDT 0.6B v3" (multilingual) when Handy asks.
EOF
if [[ "$OS" == "Darwin" ]]; then
  cat <<'EOF'
  → Grant Microphone and Accessibility access when prompted
    (System Settings → Privacy & Security). Default shortcut: Option+Space.
EOF
else
  cat <<'EOF'
  → In Handy's settings, set the paste shortcut to Ctrl+Shift+V so it
    works in terminals, and set the overlay position to None on Wayland.
EOF
fi
