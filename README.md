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
- Ghostty, Kitty, and Konsole configs (`ghostty/`, `kitty/`, `konsole/`)
- terminal appearance and behavior settings

This directory affects how terminals look and behave, not what they execute.

`./install.sh` installs one terminal config. Choose it with
`--terminal=ghostty|kitty|konsole|none` or `DOTFILES_TERMINAL=...`;
otherwise it uses Konsole on Linux and, on macOS, Ghostty if installed,
then Kitty. To switch later, run that terminal's installer directly,
e.g. `bash kitty/install.sh`.

---

## macOS without Homebrew

On macOS the installer does not use Homebrew. Every tool, git included,
is installed with [mise](https://mise.jdx.dev) into your home directory
(`~/.config/mise/config.toml` lists the global tools), and re-running the
installer bumps them all to their latest releases. The Xcode Command Line
Tools are still required for the macOS SDK and C compiler, which nothing
else can provide. (They also supply the git used for the first clone.)

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

