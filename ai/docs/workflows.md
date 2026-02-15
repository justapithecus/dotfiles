# Workflows

Common patterns for the AI governance toolkit.

## Plan-then-implement

The standard development loop. Plan first, implement with automatic gating.

```sh
git worktree add -b feature/my-change ../repo-my-change main
cd ../repo-my-change
ai-plan                     # read-only session; may write plan.json
ai-implement                # consumes plan.json, auto-gates on exit
```

`ai-implement` determines the governance mode from the diff profile
(PATCH/NORMAL/STRUCTURAL/API/HEAVY) and runs `ai-check` automatically.
On failure, it offers re-entry with findings injected (up to 3 iterations).

## Quick patch

For small, scoped changes. Three-phase workflow: plan, emit, validate.

```sh
ai-patch "fix the typo in README.md"
```

Phase 1 (Claude, patch-architect) plans the changes. Phase 2 (Codex,
patcher) emits minimal diffs. Phase 3 runs `ai-check --bundle patch`.

## Manual governance check

Run governance checks explicitly with mode or bundle routing.

```sh
ai-check --mode NORMAL --base main           # 15 skills, cost-ordered
ai-check --mode PATCH --base main            # 7 skills, surgical
ai-check --mode STRUCTURAL --base main       # 17 skills, structural
ai-check --mode API --base main              # 13 skills, API surface
ai-check --mode HEAVY --base main            # 43 skills, full daily driver
ai-check --mode AUDIT --base main            # 43 skills, full audit

ai-check --bundle default                    # bundle routing (listing order)
ai-check --bundle patch --fail-fast --base main
```

`--mode` orders skills by cost then mode type. `--bundle` uses listing order.

Note: `ai-implement` passes `--diff-profile` to `ai-check` automatically,
enabling predicate filtering. Manual invocations run all mode-selected
skills unless `--diff-profile` is explicitly provided.

## Single skill validation

Run one skill in isolation for targeted checks.

```sh
ai-skill repo-convention-enforcer
ai-skill scope-violation-detector --base main
ai-skill arch-index-alignment --scope ai/
```

Skills output unified JSON: `{skill, version, status, blocking, major, warning, info}`.

## Interactive chat

Open a Claude session with a specific cognitive role.

```sh
ai-chat                      # default: architect
ai-chat planner              # task breakdown, no code
ai-chat reviewer             # code review perspective
ai-chat implementer          # implementation guidance
```

## Migration

Onboard an existing repository to the governance framework.

```sh
ai-migrate /path/to/repo     # six-phase scaffolder
ai-migrate                   # defaults to current directory
```

Phases: Scan, ARCH_INDEX, CLAUDE.md, Scaffolds, Baselines, Validate.

## Troubleshooting

**"claude not found"**
Run `./ai/deps.sh` to install claude and codex.

**"yq not found"**
Run `./ai/deps.sh` or install yq manually (e.g., `brew install yq`).

**"cannot locate ai/ directory"**
Set `AI_DIR` environment variable or run `./ai/install.sh` to reinstall.

**"All skills were skipped"**
Most skills need diff context. Pass `--base <ref>`:
```sh
ai-check --mode NORMAL --base main
```

**"refusing to implement on 'main'"**
Create a worktree first:
```sh
git worktree add -b my-branch ../repo-suffix main
```
