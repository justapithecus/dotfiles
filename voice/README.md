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

1. Pick a model when Handy asks. **Parakeet V2** (English) or **Parakeet V3**
   (25 European languages) — accurate, fast, CPU-only.
2. Shortcut: Option+Space on macOS by default; Meta+Shift+V on KDE (installed
   by this script, since Wayland apps can't register global shortcuts).

### macOS

- Grant **Microphone** and **Accessibility** access (System Settings →
  Privacy & Security).
- If the old clipboard gets pasted instead of the transcript, raise Handy's
  paste delay to 60–200 ms.

### Linux (KDE / Wayland)

- Set Handy's paste shortcut to **Ctrl+Shift+V** so it works in terminals.
- Set the overlay position to **None**; the overlay can steal focus and
  break pasting.
- The KDE shortcut toggles recording (tap to start, tap to stop) rather than
  hold-to-talk.
