# bosun

[Bosun](https://github.com/pithecene/bosun) runs a repository's development
process: worktrees, checks, branch review, and pull request submission. Its
releases come from a private repository, so this install is opt-in.

## Install

```sh
./install.sh --with-bosun        # or DOTFILES_BOSUN=1 ./install.sh
bash bosun/install.sh            # on its own
```

The script pins Bosun with `mise use -g`, which writes
`~/.config/mise/config.toml`. Without `GITHUB_TOKEN` it uses the token from
`gh auth token`, which must be able to read `pithecene/bosun`.

## Shell integration

`shell/zsh/aliases.zsh` defines the `bo*` aliases only when `bosun` is on
`PATH`, so a shell without Bosun gets none of them.

## Repository configuration

`bosun.yaml` at the repository root configures Bosun for this repository.
It has no effect unless Bosun is installed.
