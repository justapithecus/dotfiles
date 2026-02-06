# gastown

[Gas Town](https://github.com/steveyegge/gastown) (`gt`) is a multi-agent workspace manager for Claude Code with persistent work tracking.

## Install

```sh
bash tools/gastown/install.sh
```

This sets up Go 1.25.6 via mise (global) and installs the `gt` binary via `go install`.

After install, create a workspace:

```sh
gt install ~/gt --git
```

## Shell integration

`env.sh` adds `~/go/bin` to PATH so `gt` is available in all shells.
This is sourced automatically via `shell/zsh/env.zsh`.

## How it differs from ai/tools/

`ai/tools/` contains agent-built tools that operate during live sessions.
gastown manages multi-agent orchestration and does not live under the AI substrate.
