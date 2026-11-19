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
├── editor/      # Editor configuration (nvim/)
├── terminal/    # Terminal emulator configuration (ghostty/, kitty/, konsole/)
├── fonts/       # Font assets
└── voice/       # Speech-to-text input
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
- Neovim configuration (`nvim/`, built on LazyVim)
- editor-specific keybindings
- editor plugins and settings

This directory is editor-specific and intentionally isolated from shell logic.

---

## `terminal/`

Terminal emulator configuration.

Typical contents:
- Ghostty, Kitty, and Konsole configs (`terminal/ghostty/`, `terminal/kitty/`, `terminal/konsole/`)
- terminal appearance and behavior settings

This directory affects how terminals look and behave, not what they execute.

`./install.sh` installs one terminal config. Choose it with
`--terminal=ghostty|kitty|konsole|none` or `DOTFILES_TERMINAL=...`;
otherwise it uses Konsole on Linux and, on macOS, Ghostty if installed,
then Kitty. To switch later, run that terminal's installer directly,
e.g. `bash terminal/kitty/install.sh`.

---

## macOS without Homebrew

On macOS the installer uses no Homebrew, Xcode Command Line Tools, or
conda. Every tool is a prebuilt binary installed with
[mise](https://mise.jdx.dev) into your home directory
(`~/.config/mise/config.toml` lists them), and re-running the installer
bumps them all to their latest releases.

git is GitHub Desktop's relocatable build
([dugite-native](https://github.com/desktop/dugite-native)). Nothing in
this repo compiles code on macOS, so no C toolchain is installed.

A fresh Mac has no git (`/usr/bin/git` only offers to install the Xcode
tools), so bootstrap from a tarball, then switch to a real clone:

```sh
curl -fsSL https://github.com/justapithecus/dotfiles/archive/main.tar.gz | tar xz
./dotfiles-main/install.sh
# new shell: git now comes from mise
git clone git@github.com:justapithecus/dotfiles ~/workspace/justapithecus/dotfiles
~/workspace/justapithecus/dotfiles/install.sh   # re-point AI tooling at the clone
rm -rf dotfiles-main
```

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

