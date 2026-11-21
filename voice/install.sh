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
  local bin="$HOME/.local/bin" stamp="$HOME/.local/share/handy-appimage-version" current=""
  mkdir -p "$bin" "$(dirname "$stamp")"
  [[ -f "$stamp" && -x "$bin/handy" ]] && current="$(cat "$stamp")"

  # The AppImage bundles gtk-layer-shell and runs from the home directory, so
  # Handy itself needs no root. Copied, not linked (see AGENTS.md).
  if [[ "$current" == "$VERSION" ]]; then
    echo "  ✔ Handy $VERSION already installed"
  else
    local appimage
    case "$ARCH" in
      x86_64)  appimage="$(fetch_asset '_amd64\.AppImage$')" ;;
      aarch64) appimage="$(fetch_asset '_aarch64\.AppImage$')" ;;
      *) echo "✖ Unsupported Linux arch: $ARCH" >&2; exit 1 ;;
    esac
    stop_handy
    install -m 0755 "$appimage" "$bin/handy"
    echo "$VERSION" > "$stamp"
    echo "  ✔ Handy $VERSION installed to $bin/handy"
  fi

  install_linux_typing
  install_linux_desktop
  install_linux_model
  configure_linux_handy
}

# Handy pastes by sending a key combination. wtype cannot on KDE (KWin has no
# virtual-keyboard protocol), so KDE needs ydotool, whose daemon writes to
# /dev/uinput. The login session's ACL already grants the user that device.
install_linux_typing() {
  if ! command -v ydotool >/dev/null 2>&1; then
    sudo zypper -n install ydotool
  fi
  systemctl --user daemon-reload
  systemctl --user enable --now ydotool.service
  echo "  ✔ ydotool daemon running (Handy pastes through it)"
}

# Launcher, start at login (hidden), and the KDE shortcut. Wayland apps cannot
# grab global shortcuts, so KDE runs `handy --toggle-transcription` instead.
install_linux_desktop() {
  local apps="$HOME/.local/share/applications" accel="$HOME/.local/share/kglobalaccel"
  mkdir -p "$apps" "$accel" "$HOME/.config/autostart"
  sed "s|@BIN@|$HOME/.local/bin|" "$SCRIPT_DIR/linux/handy.desktop" > "$apps/handy.desktop"
  sed "s|@BIN@|$HOME/.local/bin|" "$SCRIPT_DIR/linux/handy-autostart.desktop" > "$HOME/.config/autostart/handy.desktop"
  sed "s|@BIN@|$HOME/.local/bin|" "$SCRIPT_DIR/kde/handy-toggle.desktop" > "$accel/handy-toggle.desktop"
  # Rebuild the service cache so Handy appears in the launcher without a logout.
  command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true

  # The voice-record entries that Handy replaced hold Meta+Shift+V; set them aside.
  local old retired="$HOME/.local/share/kglobalaccel.retired"
  for old in voice-record-start voice-record-stop; do
    [[ -f "$accel/$old.desktop" ]] || continue
    mkdir -p "$retired"
    mv "$accel/$old.desktop" "$retired/"
    kglobalaccel_set "['$old.desktop','InvokeAction','','']" "[]"
  done

  # kglobalaccel reads $accel at login; register now as well, so the shortcut
  # works without logging out. Flag 2 arms it, 4 sets this key.
  local meta_shift_v=$(( 0x10000000 | 0x02000000 | 0x56 ))
  kglobalaccel_call doRegister "['handy-toggle.desktop','InvokeAction','Handy: Toggle Transcription','Toggle transcription']" >/dev/null \
    && kglobalaccel_set "['handy-toggle.desktop','InvokeAction','Handy: Toggle Transcription','Toggle transcription']" "[$meta_shift_v]" \
    && echo "  ✔ KDE shortcut: Meta+Shift+V toggles recording" \
    || echo "  ⚠ KDE shortcut not registered now; it takes effect at the next login"
}

kglobalaccel_call() {
  command -v gdbus >/dev/null 2>&1 || return 1
  gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method "org.kde.KGlobalAccel.$1" "${@:2}"
}

kglobalaccel_set() { kglobalaccel_call setShortcut "$1" "$2" 6 >/dev/null; }

# The recommended English model, from the Hugging Face cache Handy reads. Its
# revision, file and SHA-256 come from the catalog shipped with this release.
HANDY_MODEL_ID="parakeet-tdt-0.6b-v2"

install_linux_model() {
  local catalog="$TMP/catalog.json" repo rev file sha dir
  curl -fsSL "https://raw.githubusercontent.com/$REPO/v$VERSION/src-tauri/src/catalog/catalog.json" -o "$catalog"
  read -r repo rev file sha < <(yq -p json -o tsv \
    ".models[] | select(.id == \"$HANDY_MODEL_ID\") | [.repository, .revision, .files[.quant].filename, .files[.quant].sha256]" "$catalog")
  [[ -n "$sha" ]] || { echo "✖ $HANDY_MODEL_ID is not in Handy $VERSION's catalog" >&2; exit 1; }
  dir="${HF_HOME:-$HOME/.cache/huggingface}/hub/models--${repo//\//--}/snapshots/$rev"
  HANDY_MODEL="$repo/$file"
  if [[ -f "$dir/$file" ]]; then
    echo "  ✔ Model $HANDY_MODEL_ID already downloaded"
    return
  fi
  mkdir -p "$dir"
  curl -fL --progress-bar "https://huggingface.co/$repo/resolve/$rev/$file" -o "$dir/$file.part"
  [[ "$(sha256sum "$dir/$file.part" | cut -d' ' -f1)" == "$sha" ]] \
    || { rm -f "$dir/$file.part"; echo "✖ Checksum mismatch for $file" >&2; exit 1; }
  mv "$dir/$file.part" "$dir/$file"
  echo "  ✔ Model $HANDY_MODEL_ID downloaded"
}

# Every running Handy: the installer's own unit, the one the login autostart
# entry runs (app-handy@autostart), and one opened from the launcher. Handy
# holds its settings in memory, so it must stop before they are edited.
stop_handy() {
  systemctl --user stop app-handy.service 'app-handy@*.service' >/dev/null 2>&1 || true
}

# Skip onboarding, select the model, and show the live overlay with start and
# stop sounds. Linux defaults the overlay off because some compositors give it
# focus; KDE draws it as a layer-shell surface that takes none, so the paste
# still reaches the focused window. Handy writes its settings on first start,
# so start it once if they do not exist yet.
configure_linux_handy() {
  local settings="$HOME/.local/share/com.pais.handy/settings_store.json"
  stop_handy
  if [[ ! -f "$settings" ]]; then
    systemd-run --user --quiet --collect --unit=app-handy --slice=app.slice "$HOME/.local/bin/handy" --start-hidden
    for _ in $(seq 1 30); do [[ -f "$settings" ]] && break; sleep 1; done
    stop_handy
  fi
  [[ -f "$settings" ]] || { echo "⚠ Handy wrote no settings; pick the model in its window"; return; }
  python3 - "$settings" "$HANDY_MODEL" <<'PY'
import json, pathlib, sys
path, model = pathlib.Path(sys.argv[1]), sys.argv[2]
doc = json.loads(path.read_text())
settings = doc.get("settings", doc)
settings["onboarding_completed"] = True
settings["selected_model"] = settings.get("selected_model") or model
settings["overlay_style"] = "live"
settings["overlay_position"] = "bottom"
# The login entry passes --start-hidden; the setting would hide the launcher too.
settings["start_hidden"] = False
# The sounds mark the start and stop of a recording.
settings["audio_feedback"] = True
path.write_text(json.dumps(doc, indent=2))
PY
  systemd-run --user --quiet --collect --unit=app-handy --slice=app.slice "$HOME/.local/bin/handy" --start-hidden
  echo "  ✔ Handy configured and running"
}

case "$OS" in
  Darwin) install_macos ;;
  Linux)  install_linux ;;
  *) echo "✖ Unsupported OS: $OS" >&2; exit 1 ;;
esac

if [[ "$OS" == "Darwin" ]]; then
  cat <<'EOF'
  → First launch: pick "Parakeet TDT 0.6B v2" (English) or
    "Parakeet TDT 0.6B v3" (multilingual) when Handy asks.
  → Grant Microphone and Accessibility access when prompted
    (System Settings → Privacy & Security). Default shortcut: Option+Space.
EOF
fi
