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
├── GOVERNANCE.md          # Agentic governance model specification
├── install.sh             # Copies scripts to ~/.local/bin
├── deps.sh                # Installs claude and codex
├── skills.yaml            # Skill + bundle registry (43 skills, 6 bundles)
├── bin/                   # Executable entrypoint scripts
│   ├── ai-chat.sh         # Interactive Claude with role selection
│   ├── ai-plan.sh         # Planner mode (read-only)
│   ├── ai-implement.sh    # Implementer mode
│   ├── ai-review.sh       # Codex reviewer mode
│   ├── ai-patch.sh        # Three-phase surgery workflow
│   ├── ai-skill.sh        # Single skill runner
│   ├── ai-check.sh        # Bundle orchestrator
│   ├── ai-list.sh         # Registry listing
│   ├── ai-help.sh         # Help and usage reference
│   ├── ai-install-hooks.sh # Git hook installer
│   └── ai-migrate.sh     # Repo migration scaffolder (Phase A-F)
├── roles/                 # Cognitive role definitions
├── skills/                # Skill definitions (43 skills across 7 domains)
├── docs/                  # Explanatory guides (quickstart, workflows)
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
ai-plan              # read-only planning (writes plan.json for aii)
ai-implement         # implementation with auto-gating loop
ai-review            # Codex code review
ai-patch "task"      # three-phase surgery workflow
```

The `ai-implement` (alias: `aii`) workflow:
1. Preflight: checks branch, detects merge base, consumes plan.json
2. Launches interactive Claude session
3. After session: computes diff profile, determines governance mode
4. Runs `ai-check --mode <MODE>` automatically
5. On failure: offers to re-enter session with findings injected
6. On pass: saves last.patch + last.report.json, exits blessed

Governance (see `GOVERNANCE.md` for full spec; automatic via `--mode` or manual via `--bundle`):
```sh
ai-check --mode NORMAL              # auto-routed (15 skills)
ai-check --mode PATCH               # surgical edits (7 skills)
ai-check --mode STRUCTURAL          # structural changes (17 skills)
ai-check --mode API                 # API/contract changes (13 skills)
ai-check --mode HEAVY               # large features (43 skills)
ai-check --mode AUDIT               # full-spectrum audit (43 skills)
ai-check --bundle default           # backward-compat bundle routing
ai-check --bundle heavy             # backward-compat bundle routing
ai-skill repo-convention-enforcer   # run a single skill
ai-list                             # list skills, bundles, and roles
ai-install-hooks                    # install pre-push hook
ai-migrate /path/to/repo            # Phase A-F repo migration
```

Help:
```sh
ai-help                             # command overview
ai-help <command>                   # per-command usage
ai-help workflows                   # common patterns
```

## Skills

Skills are non-interactive JSON validators invoked by `ai-skill` and
orchestrated by `ai-check`. Each skill outputs a unified JSON schema:

```json
{
  "skill": "name",
  "version": "v1",
  "status": "pass|fail",
  "blocking": [],
  "major": [],
  "warning": [],
  "info": []
}
```

Severity model:
- **BLOCKING** — hard violations that must prevent merge (exit code 1)
- **MAJOR** — significant issues that should be addressed
- **WARNING** — potential concerns worth reviewing
- **INFO** — observations and context

Skills are ordered by cost (cheap → moderate → heavy), then by
mode (deterministic → heuristic → semantic). Bundles list skills in
this conventional order; `ai-check` executes them in listing order.

### Domain I — Structural Integrity (7 skills)

| Skill | Cost | Mode |
|-------|------|------|
| `repo-convention-enforcer` | cheap | deterministic |
| `arch-index-alignment` | cheap | deterministic |
| `undocumented-module-detector` | cheap | heuristic |
| `orphan-directory-detector` | cheap | deterministic |
| `forbidden-top-level-detector` | cheap | deterministic |
| `required-directory-detector` | cheap | deterministic |
| `module-name-collision-detector` | cheap | heuristic |

### Domain II — Architectural Boundaries (7 skills)

| Skill | Cost | Mode |
|-------|------|------|
| `dependency-layer-violation` | moderate | deterministic |
| `cross-module-coupling-detector` | moderate | heuristic |
| `circular-dependency-detector` | moderate | deterministic |
| `boundary-leak-detector` | moderate | heuristic |
| `inversion-of-control-violation` | moderate | heuristic |
| `internal-package-exposure-detector` | moderate | deterministic |
| `forbidden-import-pattern-detector` | moderate | deterministic |

### Domain III — Dependency Graph Integrity (5 skills)

| Skill | Cost | Mode |
|-------|------|------|
| `unstable-dependency-detector` | heavy | heuristic |
| `excessive-fan-in-detector` | heavy | heuristic |
| `excessive-fan-out-detector` | heavy | heuristic |
| `god-module-detector` | heavy | heuristic |
| `module-cohesion-anomaly-detector` | heavy | heuristic |

### Domain IV — API & Contract Stability (5 skills)

| Skill | Cost | Mode |
|-------|------|------|
| `api-surface-drift` | moderate | deterministic |
| `serialization-contract-drift` | moderate | deterministic |
| `config-contract-drift` | moderate | deterministic |
| `cli-contract-drift` | moderate | deterministic |
| `backward-compatibility-violation-detector` | heavy | semantic |

### Domain V — Change Discipline (5 skills)

| Skill | Cost | Mode |
|-------|------|------|
| `scope-violation-detector` | cheap | deterministic |
| `unexpected-file-creation-detector` | cheap | deterministic |
| `refactor-without-declaration-detector` | cheap | deterministic |
| `large-diff-anomaly-detector` | cheap | deterministic |
| `semantic-drift-detector` | heavy | semantic |

### Domain VI — Entropy & Complexity Control (7 skills)

| Skill | Cost | Mode |
|-------|------|------|
| `responsibility-duplication-detector` | heavy | heuristic |
| `near-duplicate-file-detector` | heavy | heuristic |
| `abstraction-leak-detector` | heavy | semantic |
| `unused-public-symbol-detector` | moderate | heuristic |
| `dead-module-detector` | moderate | heuristic |
| `orphan-test-detector` | moderate | heuristic |
| `test-coverage-regression-detector` | heavy | deterministic |

### Domain VII — Repository Hygiene & Operational Safety (7 skills)

| Skill | Cost | Mode |
|-------|------|------|
| `unsafe-config-pattern-detector` | cheap | deterministic |
| `environment-variable-leak-detector` | cheap | deterministic |
| `hardcoded-secret-pattern-detector` | cheap | deterministic |
| `unbounded-error-swallow-detector` | moderate | heuristic |
| `unlogged-error-detector` | moderate | heuristic |
| `inconsistent-error-propagation-detector` | moderate | heuristic |
| `panic-or-exit-misuse-detector` | moderate | heuristic |

## Bundles

Bundles group skills for common workflows. Skills within a bundle are
executed in listing order, with `--fail-fast` stopping on first blocking
failure.

| Bundle | Skills | Purpose |
|--------|--------|---------|
| `patch` | 7 | Surgical edits (fast, strict, scoped) |
| `default` | 15 | Normal work (broad coverage, reasonable cost) |
| `structural-change` | 17 | Module structure / directory changes |
| `api-change` | 13 | Public API, SDK, CLI, contract changes |
| `heavy` | 43 | Large features/refactors (maximal daily driver) |
| `audit-full` | 43 | Full-spectrum audit (absolute coverage) |

## Roles

- `architect` — system design and tradeoff explanations
- `planner` — task breakdowns and sequencing (no code)
- `reviewer` — code review with concrete issues
- `implementer` — precise edits when explicitly asked
- `patch-architect` — scoped change reasoning (≤ 3 files)
- `patcher` — minimal unified diff emission (Codex-targeted)

## Guides

- `docs/quickstart.md` -- first-time setup and first workflow
- `docs/workflows.md` -- common patterns and troubleshooting

## How the prompt is assembled

Each entrypoint script builds a system prompt in this order:

1. Preamble (mode declaration, repo root).
2. `CLAUDE.md` — the constitutional authority.
3. Optional context layers from `context/*.md` (sorted).
4. The role prompt from `roles/`.
5. Repository `AGENTS.md` content (if present at repo root).
6. Repository `ARCH_INDEX.md` content (checks root and `docs/`).

Scripts resolve paths via a portable symlink-following loop so they
work correctly when installed to `~/.local/bin` as copies.
