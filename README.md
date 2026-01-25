# dotfiles

Linux userland and development environment configurations

## Directory overview

- [ai](ai/) — AI tooling scripts plus context and role definitions.
- [git](git/) — Placeholder directory for git-related configuration (currently empty).
- [helix](helix/) — Placeholder directory for Helix editor configuration (currently empty).
- [konsole](konsole/) — Konsole profiles and color schemes.
- [nvim](nvim/) — Neovim config bundle (install script, overlay, package list).
- [scripts](scripts/) — Placeholder directory for standalone scripts (currently empty).
- [shell](shell/) — Shell setup (install script, starship, zsh configs).

## Conventions and principles

This repo favors copy-based installs (no symlinks) and idempotent scripts that can be run repeatedly without manual cleanup. The intent is a one-shot bootstrap flow at the root, with each subdirectory owning its own install script for local concerns. In practice this means installers create needed directories and overwrite target files rather than link them.

These conventions are reflected in `install.sh` at the repo root and the corresponding `install.sh` files inside each subtree.

## Top-level files

- [AGENTS.md](AGENTS.md) — Repository-specific instructions for automated agents.
- [install.sh](install.sh) — Root installer entrypoint for dotfiles setup.
- [README.md](README.md) — This overview.
