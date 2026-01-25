# Shell

Zsh configuration with ZDOTDIR-based layout and Starship prompt.

## Contents

- `install.sh`: Installs zsh config files to `~/.config/zsh`.
- `starship.toml`: Starship prompt configuration.
- `zsh/`: Zsh configuration modules.

## Install

```sh
./shell/install.sh
```

This sets up:
- `ZDOTDIR` pointing to `~/.config/zsh` (via `~/.zshenv`).
- Modular zsh config sourced from `.zshrc`.
- Starship prompt config at `~/.config/starship.toml`.

## Zsh modules

| File              | Purpose                              |
|-------------------|--------------------------------------|
| `.zshrc`          | Main entrypoint, sources all modules |
| `env.zsh`         | Environment variables and PATH       |
| `aliases.zsh`     | Shell aliases                        |
| `completions.zsh` | Completion system setup              |
| `compdefs.zsh`    | Command-specific completion defs     |
| `keybindings.zsh` | Key bindings (emacs mode, etc.)      |
| `word-jump.zsh`   | Word navigation tweaks               |

## Prompt

Uses [Starship](https://starship.rs/) with a minimal format:
```
user@host ~/path branch status ❯
```
