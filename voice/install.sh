#!/usr/bin/env bash
# voice/install.sh — install voice input tooling
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -d "$REPO_ROOT/dotfiles/voice" ]]; then
  DOTFILES_DIR="$REPO_ROOT/dotfiles"
else
  DOTFILES_DIR="$REPO_ROOT"
fi

VOICE_SRC="$DOTFILES_DIR/voice"
ZDOTDIR_PATH="${ZDOTDIR:-$HOME/.config/zsh}"

copy() { rm -f "$2"; cp -f "$1" "$2"; }

# ── Install voice scripts ──────────────────────────────────────────
echo "  → Installing voice scripts"
mkdir -p "$HOME/.local/bin"
for cmd in voice-record voice-paste; do
  copy "$VOICE_SRC/bin/$cmd" "$HOME/.local/bin/$cmd"
  chmod +x "$HOME/.local/bin/$cmd"
done

# ── Install config (skip if user already has one) ──────────────────
echo "  → Installing voice config"
mkdir -p "$HOME/.config/voice"
if [[ ! -f "$HOME/.config/voice/config.env" ]]; then
  copy "$VOICE_SRC/config/config.env" "$HOME/.config/voice/config.env"
else
  echo "    (config.env already exists, skipping)"
fi

# ── Create state directory ─────────────────────────────────────────
mkdir -p "$HOME/.config/voice/state"

# ── Install zsh bindings ───────────────────────────────────────────
echo "  → Installing zsh voice bindings"
mkdir -p "$ZDOTDIR_PATH"
copy "$DOTFILES_DIR/shell/zsh/voice-bindings.zsh" "$ZDOTDIR_PATH/voice-bindings.zsh"

# ── Build whisper.cpp from source ──────────────────────────────────
WHISPER_DIR="$HOME/.local/src/whisper.cpp"
WHISPER_BIN="$HOME/.local/bin/whisper-cli"

if command -v whisper-cli >/dev/null 2>&1; then
  echo "  → whisper-cli already installed, skipping build"
else
  echo "  → Building whisper.cpp from source"

  # Install build dependencies
  if command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y cmake gcc-c++ make git alsa-utils || true
  fi

  if [[ -d "$WHISPER_DIR" ]]; then
    echo "    Updating existing checkout"
    git -C "$WHISPER_DIR" pull --ff-only 2>/dev/null || true
  else
    mkdir -p "$(dirname "$WHISPER_DIR")"
    git clone https://github.com/ggml-org/whisper.cpp.git "$WHISPER_DIR"
  fi

  cmake -B "$WHISPER_DIR/build" -S "$WHISPER_DIR" -DCMAKE_BUILD_TYPE=Release
  cmake --build "$WHISPER_DIR/build" -j"$(nproc)" --config Release

  # Install binary
  if [[ -f "$WHISPER_DIR/build/bin/whisper-cli" ]]; then
    cp -f "$WHISPER_DIR/build/bin/whisper-cli" "$WHISPER_BIN"
    chmod +x "$WHISPER_BIN"
    echo "  ✔ whisper-cli installed to $WHISPER_BIN"
  else
    echo "  ✖ whisper-cli build failed — binary not found"
    echo "    Try building manually: cd $WHISPER_DIR && cmake -B build && cmake --build build"
  fi
fi

# ── Download model if missing ──────────────────────────────────────
MODEL_DIR="$HOME/.local/share/whisper"
MODEL_FILE="$MODEL_DIR/ggml-base.en.bin"

if [[ -f "$MODEL_FILE" ]]; then
  echo "  → Model already present: $MODEL_FILE"
else
  echo "  → Downloading whisper base.en model"
  mkdir -p "$MODEL_DIR"

  if [[ -f "$WHISPER_DIR/models/download-ggml-model.sh" ]]; then
    bash "$WHISPER_DIR/models/download-ggml-model.sh" base.en
    # The script downloads to whisper.cpp/models/; move to our location
    if [[ -f "$WHISPER_DIR/models/ggml-base.en.bin" ]]; then
      cp -f "$WHISPER_DIR/models/ggml-base.en.bin" "$MODEL_FILE"
      echo "  ✔ Model installed to $MODEL_FILE"
    fi
  else
    MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
    if command -v curl >/dev/null 2>&1; then
      curl -L -o "$MODEL_FILE" "$MODEL_URL"
      echo "  ✔ Model downloaded to $MODEL_FILE"
    elif command -v wget >/dev/null 2>&1; then
      wget -O "$MODEL_FILE" "$MODEL_URL"
      echo "  ✔ Model downloaded to $MODEL_FILE"
    else
      echo "  ✖ Cannot download model — install curl or wget"
      echo "    Download manually: $MODEL_URL → $MODEL_FILE"
    fi
  fi
fi

# ── Summary ────────────────────────────────────────────────────────
echo
if ! command -v whisper-cli >/dev/null 2>&1 && [[ ! -x "$WHISPER_BIN" ]]; then
  echo "  ⚠ whisper-cli not found in PATH"
  echo "    Ensure $HOME/.local/bin is in your PATH"
fi
if [[ ! -f "$MODEL_FILE" ]]; then
  echo "  ⚠ Whisper model not found: $MODEL_FILE"
  echo "    Download: https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
fi
echo "  ✔ Voice input installation complete"
