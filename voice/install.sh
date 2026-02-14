#!/usr/bin/env bash
# voice/install.sh — install voice input tooling
set -euo pipefail

sudo -v

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -d "$REPO_ROOT/dotfiles/voice" ]]; then
  DOTFILES_DIR="$REPO_ROOT/dotfiles"
else
  DOTFILES_DIR="$REPO_ROOT"
fi

VOICE_SRC="$DOTFILES_DIR/voice"
ZDOTDIR_PATH="${ZDOTDIR:-$HOME/.config/zsh}"
WHISPER_DIR="$HOME/.local/src/whisper.cpp"
WHISPER_BIN="$HOME/.local/bin/whisper-cli"
MODEL_DIR="$HOME/.local/share/whisper"
MODEL_FILE="$MODEL_DIR/ggml-tiny.en.bin"

copy() { rm -f "$2"; cp -f "$1" "$2"; }

# ── Voice scripts ────────────────────────────────────────────────
echo "  → Installing voice scripts"
mkdir -p "$HOME/.local/bin"
for cmd in voice-record voice-paste; do
  copy "$VOICE_SRC/bin/$cmd" "$HOME/.local/bin/$cmd"
  chmod +x "$HOME/.local/bin/$cmd"
done

# ── Config ───────────────────────────────────────────────────────
echo "  → Installing voice config"
mkdir -p "$HOME/.config/voice" "$HOME/.config/voice/state"
copy "$VOICE_SRC/config/config.env" "$HOME/.config/voice/config.env"

# ── Zsh bindings ─────────────────────────────────────────────────
echo "  → Installing zsh voice bindings"
mkdir -p "$ZDOTDIR_PATH"
copy "$DOTFILES_DIR/shell/zsh/voice-bindings.zsh" "$ZDOTDIR_PATH/voice-bindings.zsh"

# ── KDE global shortcuts ────────────────────────────────────────
KDE_SHORTCUT_DIR="$HOME/.local/share/kglobalaccel"
echo "  → Installing KDE global shortcuts"
mkdir -p "$KDE_SHORTCUT_DIR"
for desktop_file in "$VOICE_SRC/kde"/*.desktop; do
  [[ -f "$desktop_file" ]] || continue
  sed "s|PLACEHOLDER_VOICE_RECORD|$HOME/.local/bin/voice-record|g" \
    "$desktop_file" > "$KDE_SHORTCUT_DIR/$(basename "$desktop_file")"
done

# ── System dependencies ─────────────────────────────────────────
echo "  → Installing build and runtime dependencies"
sudo zypper -n install cmake gcc-c++ make git alsa-utils wl-clipboard vulkan-devel shaderc

# ── Build whisper.cpp ────────────────────────────────────────────
echo "  → Building whisper.cpp from source"
if [[ -d "$WHISPER_DIR" ]]; then
  git -C "$WHISPER_DIR" pull --ff-only 2>/dev/null || true
else
  mkdir -p "$(dirname "$WHISPER_DIR")"
  git clone https://github.com/ggml-org/whisper.cpp.git "$WHISPER_DIR"
fi

echo "  → Building with Vulkan GPU acceleration"
rm -rf "$WHISPER_DIR/build"
cmake -B "$WHISPER_DIR/build" -S "$WHISPER_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_VULKAN=ON
cmake --build "$WHISPER_DIR/build" -j"$(nproc)" --config Release

cp -f "$WHISPER_DIR/build/bin/whisper-cli" "$WHISPER_BIN"
chmod +x "$WHISPER_BIN"
echo "  ✔ whisper-cli installed to $WHISPER_BIN"

# ── Download model ───────────────────────────────────────────────
echo "  → Downloading whisper tiny.en model"
mkdir -p "$MODEL_DIR"
curl -L -o "$MODEL_FILE" \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin"

echo "  ✔ Voice input installation complete"
