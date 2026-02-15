# AI tooling

This directory contains the AI governance framework: entrypoint scripts,
role prompts, skills, and bundle orchestration for AI-assisted development
using Claude Code (with Codex CLI retained for review and patch workflows).

## Directory Layout

```
ai/
├── CLAUDE.md              # Constitutional authority (sovereign)
├── REVIEW_ARCHITECTURE.md # Tool separation policy
├── MIGRATION.md           # Migration protocol for existing repos
├── install.sh             # Copies scripts to ~/.local/bin
├── deps.sh                # Installs claude and codex
├── skills.yaml            # Skill + bundle registry
├── bin/                   # Executable entrypoint scripts
│   ├── ai-chat.sh         # Interactive Claude with role selection
│   ├── ai-plan.sh         # Planner mode (read-only)
│   ├── ai-implement.sh    # Implementer mode
│   ├── ai-review.sh       # Codex reviewer mode
│   ├── ai-patch.sh        # Three-phase surgery workflow
│   ├── ai-skill.sh        # Single skill runner
│   ├── ai-check.sh        # Bundle orchestrator
│   ├── ai-list.sh         # Registry listing
│   ├── ai-install-hooks.sh # Git hook installer
│   └── ai-migrate-repo.sh # Repo migration scaffolder
├── roles/                 # Cognitive role definitions
├── skills/                # Skill definitions (7 skills)
├── completion/            # Shell completion scripts
├── context/               # Optional context layers
├── templates/             # Migration scaffolds
└── out/                   # Runtime artifacts (gitignored)
```

## Requirements

- `claude` (Claude Code) for chat, plan, implement, check, and skill scripts.
- `codex` (OpenAI Codex CLI) for review and patch scripts.
- `jq` for JSON validation.
- `yq` for YAML registry parsing.

## Install

```sh
./ai/deps.sh      # installs claude and codex
./ai/install.sh    # copies scripts to ~/.local/bin
```

Scripts are copied to `~/.local/bin` without the `.sh` extension
(e.g., `ai-chat`, `ai-check`, `ai-skill`).

## Usage

Interactive chat with a role (default: architect):
```sh
ai-chat [role]
```

Specialized entrypoints:
```sh
ai-plan              # read-only task planning
ai-implement         # Claude Code implementation session
ai-review            # Codex code review
ai-patch "task"      # three-phase surgery workflow
```

Governance:
```sh
ai-check                        # run default bundle
ai-check --bundle heavy          # run all skills
ai-check --bundle patch          # run patch-scoped skills
ai-skill repo-convention-enforcer # run a single skill
ai-list                          # list skills, bundles, and roles
ai-install-hooks                 # install pre-push hook
ai-migrate-repo /path/to/repo   # scaffold governance for a repo
```

## Skills

Skills are non-interactive JSON validators invoked by `ai-skill` and
orchestrated by `ai-check`. Each skill has:
- `SKILL.md` — instructions + `fail_on` frontmatter
- `input.schema.json` — input contract
- `output.schema.json` — output contract (enforced at validation)

Current skills:
- `repo-convention-enforcer` — structural convention validation
- `arch-index-alignment` — ARCH_INDEX vs repo structure
- `scope-violation-detector` — diff scope boundary enforcement
- `api-surface-drift` — undocumented API changes
- `dependency-layer-violation` — cross-layer import detection
- `responsibility-duplication-detector` — overlapping module responsibilities
- `large-diff-anomaly-detector` — anomalous diff patterns

## Bundles

Bundles group skills for common workflows:
- `default` — convention + arch alignment + anomaly detection
- `patch` — scope + convention + anomaly detection
- `api-change` — convention + arch + API drift + dependency layers
- `structural-change` — convention + arch + dependency + duplication
- `heavy` — all skills

## Roles

- `architect` — system design and tradeoff explanations
- `planner` — task breakdowns and sequencing (no code)
- `reviewer` — code review with concrete issues
- `implementer` — precise edits when explicitly asked
- `patch-architect` — scoped change reasoning (≤ 3 files)
- `patcher` — minimal unified diff emission (Codex-targeted)

## How the prompt is assembled

Each entrypoint script builds a system prompt in this order:

1. Preamble (mode declaration, repo root).
2. `CLAUDE.md` — the constitutional authority.
3. Optional context layers from `context/*.md` (sorted).
4. The role prompt from `roles/`.
5. Repository `AGENTS.md` content (if present at repo root).
6. Repository `docs/ARCH_INDEX.md` content (if present).

Scripts resolve paths via `readlink -f` so they work correctly
when installed to `~/.local/bin` as copies.
