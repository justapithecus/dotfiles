# Quickstart

Get the AI governance toolkit running in under five minutes.

## Prerequisites

Required:
- `git`
- `claude` (Claude Code CLI)
- `jq` (JSON processing)
- `yq` (YAML processing)

Optional:
- `codex` (OpenAI Codex CLI) — used by `ai-review` and `ai-patch`

## Install

```sh
./ai/deps.sh       # install claude and codex
./ai/install.sh     # copy scripts to ~/.local/bin
ai-help             # verify installation
```

Scripts are installed without the `.sh` extension (e.g., `ai-help`).

## First workflow

```sh
# 1. Create a worktree (never work on main directly)
git worktree add -b feature/my-change ../repo-my-change main
cd ../repo-my-change

# 2. Plan your changes (read-only, optionally writes plan.json)
ai-plan

# 3. Implement with automatic governance gating
ai-implement
# On exit: computes diff profile, determines mode, runs ai-check
# On failure: offers re-entry with findings injected
# On pass: saves last.patch + last.report.json
```

## Key concepts

- **Modes** — governance intensity levels: PATCH, NORMAL, STRUCTURAL, API, HEAVY, AUDIT
- **Skills** — non-interactive JSON validators (43 across 7 domains)
- **Bundles** — named groups of skills for common workflows
- **Roles** — cognitive profiles: architect, planner, implementer, reviewer, patch-architect, patcher

## What's next

- `ai-help <command>` — detailed usage for any command
- `ai/docs/workflows.md` — common patterns and troubleshooting
- `ai/GOVERNANCE.md` — full governance model specification
