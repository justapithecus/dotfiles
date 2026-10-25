# Repository Constitution — dotfiles

## 1. Constitutional Order of Authority

1. `ai/CLAUDE.md` (sovereign — global AI constitution)
2. This file (repo-local constitution)
3. `AGENTS.md` (behavioral expectations — also read by Codex)
4. `ARCH_INDEX.md` (structural ontology)

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

Required `ai/` subdirectories:
- `ai/bin/` — executable entrypoint scripts
- `ai/roles/` — cognitive role definitions
- `ai/skills/` — skill definitions

Forbidden:
- Executable scripts (`ai-*.sh`) at `ai/` root (must live in `ai/bin/`)
- Hardcoded `~/.config/ai` paths in scripts (use `$AI_DIR` resolution)
- Symlinks as install artifacts (copies only — symlinks break on branch switch)
- Symlinks in any git-tracked content (no symlinks, ever, in any context)
- Working directly in the main worktree (use `git worktree add` for all work)

## 4. Install Model

`ai/install.sh` copies scripts from `ai/bin/` to `~/.local/bin/`.
It never creates symlinks. It never installs to `~/.config/ai`.

## 5. Skill Registry

All skills must be registered in `ai/skills.yaml`.
Each skill directory requires: `SKILL.md`, `input.schema.json`, `output.schema.json`.
Skills use the `fail_on` frontmatter field to declare exit-code-triggering fields.
