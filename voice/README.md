# Voice

Push-to-talk speech-to-text with [Handy](https://github.com/cjpais/Handy):
free, open source (MIT), fully offline. Hold or tap a shortcut, speak, and
Handy pastes the transcript into whatever app has focus (Ghostty, Claude
Code, tmux, zsh, ...).

Handy ships its own transcription engine and downloads models in-app, so no
whisper.cpp build, recorder, or shell keybindings are needed.

## Install

```sh
./voice/install.sh
```

Installs the latest Handy release. Each download is checked against the
SHA-256 digest GitHub publishes; on macOS the app must also be notarized and
signed by Handy's developer (team `UWFLB4GC25`). Re-running upgrades Handy
when a newer release exists.

## First run

1. Pick a model when Handy asks (macOS; the Linux install picks TDT v2 itself):

   | Model | Use it for |
   |---|---|
   | **Parakeet TDT 0.6B v2** (recommended) | English push-to-talk: fastest, near-top accuracy |
   | Parakeet Unified EN 0.6B | English with live text while you speak (Handy's default pick; slightly slower) |
   | Parakeet TDT 0.6B v3 | 25 European languages, auto-detected |

   All are NVIDIA Parakeet models (~730 MB), run on the CPU, and write
   numbers as words ("three", not "3"). Handy's docs call the TDT models
   "Parakeet V2/V3".
2. Shortcut: Option+Space on macOS by default; Meta+Shift+V on KDE (installed
   by this script, since Wayland apps can't register global shortcuts).

### macOS

- Grant **Microphone** and **Accessibility** access (System Settings →
  Privacy & Security).
- If the old clipboard gets pasted instead of the transcript, raise Handy's
  paste delay to 60–200 ms.

### Linux (KDE / Wayland)

The script does the first run itself, so there is nothing to pick:

- **Handy** installs as its AppImage, copied to `~/.local/bin/handy`. It
  bundles gtk-layer-shell and needs no root.
- **Pasting** goes through `ydotool`, whose daemon runs as a user service.
  `wtype` cannot type on KDE (KWin has no virtual-keyboard protocol). The
  login session already grants the user `/dev/uinput`; only installing the
  `ydotool` package needs `sudo`, and only when it is missing.
- **Model**: Parakeet TDT 0.6B v2 downloads into the Hugging Face cache,
  checked against the SHA-256 in the release's model catalog, and is
  selected. Onboarding is marked done and the overlay is set to **None**,
  since on Wayland it can take focus and send the paste to the wrong window.
  Handy runs it on the GPU through Vulkan.
- **Shortcut**: Meta+Shift+V toggles recording (tap to start, tap to stop),
  registered at once, so no logout is needed. The old `voice-record`
  shortcut entries are moved to `~/.local/share/kglobalaccel.retired/`,
  since the start entry also held Meta+Shift+V.
- Handy starts hidden at login. It pastes with Shift+Insert, which works in
  both GUI apps and terminals.
