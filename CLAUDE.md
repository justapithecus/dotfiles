# Repository Constitution — dotfiles

## 1. Constitutional Order of Authority

1. This file (repo-local constitution)
2. `AGENTS.md` (behavioral expectations — also read by Codex)

## 2. Role of AGENTS.md

AGENTS.md provides:
- Behavioral expectations for agents and contributors
- Repository characterization for tools that do not read CLAUDE.md (e.g., Codex)
- Contribution philosophy

AGENTS.md does NOT:
- Override constitutional structural rules
- Define enforcement policy
- Weaken global prohibitions

AGENTS.md must be preserved and maintained. Codex reads AGENTS.md but
not CLAUDE.md; removing it would blind Codex to repo context.

## 3. Structural Invariants

Forbidden:
- Symlinks as install artifacts (copies only — symlinks break on branch switch)
- Symlinks in any git-tracked content (no symlinks, ever, in any context)
- Working directly in the main worktree (use `git worktree add` for all work)

## 4. Install Model

Each subtree owns its `install.sh`; the root `install.sh` calls them.
Installers copy files and never create symlinks.

This repository is public. A private tool (such as Bosun, `bosun/`) is
opt-in only: the default install never fetches it, and nothing else in the
repository requires it.
