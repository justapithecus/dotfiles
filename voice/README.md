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

1. Pick a model when Handy asks:

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

- Set Handy's paste shortcut to **Ctrl+Shift+V** so it works in terminals.
- Set the overlay position to **None**; the overlay can steal focus and
  break pasting.
- The KDE shortcut toggles recording (tap to start, tap to stop) rather than
  hold-to-talk.
