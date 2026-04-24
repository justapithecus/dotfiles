# Migration Protocol for Existing Repositories

Interactive process for migrating legacy repositories into the AI
governance system. Non-destructive, observable, and ordered.

Entrypoint: `ai-migrate /path/to/repo`

---

## Principles

1. Authority precedes enforcement.
2. Enforcement precedes automation.
3. Automation precedes strictness expansion.
4. Never combine all four in one PR.
5. No rewriting AGENTS.md during initial migration.
6. Codex boundary remains untouched.

---

## Phase A — Scan

Detect repository characteristics:

- Top-level directories
- Languages (via `go.mod`, `package.json`, `pyproject.toml`,
  `Cargo.toml`, `pom.xml`, `Gemfile`)
- Existing governance documents (`CLAUDE.md`, `AGENTS.md`)

Output: summary printed to terminal. No files modified.

---

## Phase B — Repo CLAUDE.md

If `CLAUDE.md` is absent:
- Scaffold from `ai/templates/migration/CLAUDE.md`

If `CLAUDE.md` is present:
- Print first 20 lines
- Offer review via Claude architect

---

## Phase C — Directory Scaffolds

Create governance directories:

```
repo-root/
├── ai/
│   ├── skills/
│   ├── baselines/
│   └── out/          (.gitignored)
```

Scaffold initial skill:
- `ai/skills/repo-convention-enforcer/v1/` from
  `ai/templates/migration/skill/`

Update `.gitignore`:
- Add `ai/out/` if not present

---

## Phase D — Baselines (Optional)

Capture initial repository state:

- **Directory listing** — top-level structure snapshot
- **File count metrics** — lines of code, file counts by extension

Stored in `ai/baselines/` for future drift detection.

---

## Phase E — Validate

Run governance check:

```sh
ai-check --bundle default
```

Uses `--bundle` (not `--mode`) because no diff context exists during
initial migration.

Review output. Fix any blocking violations before proceeding.

---

## Expected Order Per Repo

1. Run `ai-migrate /path/to/repo` (Phases A–E)
2. Review and customize generated files
3. Fix any violations reported in Phase E
4. Stabilize (re-run `ai-check` until clean)
5. Enable enforcement workflows
6. (Later) automate
7. (Later) tighten rules

Repeat for each repo before designing new-repo bootstrap.

---

## Acceptance Criteria (Per Repo)

- Repo-local `CLAUDE.md` exists and is authoritative
- Structural skill runs without false positives
- No major structural drift exists
- Codex review flow unchanged
- No CI regressions
- Architecture boundaries are explicit and enforceable

---

## Non-Goals

- Rewrite AGENTS.md into CLAUDE.md
- Introduce new skills beyond structural baseline
- Automate gating prematurely
- Change developer ergonomics during migration
