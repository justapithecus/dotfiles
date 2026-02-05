# Dotfiles

This repository contains my personal dotfiles: shell, editor, terminal, and
supporting scripts used on my development machines.

It also contains an `ai/` directory, which houses prompts and tooling I use to
work with AI assistants.

---

## Repository Layout

```
dotfiles/
├── ai/          # AI prompts, roles, and agent tooling
├── shell/       # Shell configuration and environment setup
├── editor/      # Editor configuration (Neovim, Helix, etc.)
├── terminal/    # Terminal emulator configuration
├── scripts/     # Miscellaneous human-facing scripts
├── fonts/       # Font assets
└── ...
```

Each top-level directory has a distinct responsibility. The intent is to keep
these responsibilities separate so that changes in one area do not cascade
unnecessarily into others.

---

## `shell/`

Shell initialization and environment wiring.

Typical contents:
- shell init files
- aliases and functions
- environment variables
- toolchain setup

This directory defines how commands execute and how the environment behaves.

---

## `editor/`

Editor configuration.

Typical contents:
- Neovim or Helix configuration
- editor-specific keybindings
- editor plugins and settings

This directory is editor-specific and intentionally isolated from shell logic.

---

## `terminal/`

Terminal emulator configuration.

Typical contents:
- Konsole profiles
- terminal appearance and behavior settings

This directory affects how terminals look and behave, not what they execute.

---

## `scripts/`

Human-facing scripts and helpers.

Typical contents:
- ad-hoc workflow helpers
- system utilities
- personal glue scripts

Scripts here are meant to be run directly by a human. Scripts that primarily
exist to support AI workflows live under `ai/` instead.

---

## `fonts/`

Font assets used by the terminal and editor configurations.

---

## `ai/`

AI-related prompts, roles, context, and tooling.

This directory exists to support how I work with AI assistants. It contains:
- prompt fragments
- role definitions
- persistent context files
- small tools used alongside agents

The internal structure of `ai/` is documented for agents in
[`ARCH_INDEX.md`](./ARCH_INDEX.md).

---

## Notes

- This repository is personal and opinionated.
- It is not intended to be a reusable dotfiles template.
- Structure matters more than polish.
- Intent is to facilitate AI to continuously bootstrap and augment itself further.

