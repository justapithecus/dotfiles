# Migration Protocol for Existing Repositories

Incremental process for migrating legacy repositories into the formalized
AI governance system. Non-destructive, observable, and ordered.

---

## Principles

1. Authority precedes enforcement.
2. Enforcement precedes automation.
3. Automation precedes strictness expansion.
4. Never combine all four in one PR.
5. No rewriting AGENTS.md during initial migration.
6. Codex boundary remains untouched.

---

## Phase 1 — Authority Alignment (Non-Enforcing)

### Step 1.1 — Add Repo-Local CLAUDE.md

Create `CLAUDE.md` at repo root using the template in
`ai/templates/migration/CLAUDE.md`.

This file:
- Declares the constitutional order of authority
- Clarifies the role of AGENTS.md (behavioral, not structural)
- Clarifies the role of ARCH_INDEX.md (ontology, not enforcement)
- Declares initial high-confidence structural invariants

This file does NOT:
- Copy or restate AGENTS.md content
- Rewrite ARCH_INDEX.md
- Change any existing behavior

### Step 1.2 — Verify No Behavioral Change

After adding CLAUDE.md, confirm:
- Existing CI passes
- Existing review flow unchanged
- No developer workflow disruption

---

## Phase 2 — Minimal Structural Skill (Observation Mode)

### Step 2.1 — Add Repo-Local Skill

Create:

```
repo-root/ai/skills/repo-convention-enforcer/v1/
  SKILL.md
  input.schema.json
  output.schema.json
```

Use templates from `ai/templates/migration/skill/`.

The skill evaluates:
- Top-level directory existence
- Major module presence
- Forbidden orphan directories
- Duplicate responsibility indicators

The skill does NOT evaluate (yet):
- Deep naming conventions
- Minor file-level rules
- Submodule constraints

### Step 2.2 — Manual Execution Only

Run from the target repo root (assumes `ai-skill` is installed to
`~/.local/bin/` via `ai/install.sh`):

```
ai-skill repo-convention-enforcer --version v1
```

Or use `ai-migrate-repo` for automated scaffolding:

```
ai-migrate-repo /path/to/repo
```

Do NOT add CI gating, block PRs, or change review workflow.

Collect and review output.

---

## Phase 3 — Drift Resolution

For each reported violation, classify:

1. **Real drift** — fix the structure
2. **Intentional exception** — update CLAUDE.md invariants
3. **Incorrect skill assumption** — update SKILL.md logic

Never silence violations without justification.
Never disable the skill.
Never patch around the system.

Proceed only after violations stabilize.

---

## Phase 4 — Enforcement Activation

### Step 4.1 — Enable Recommended PR Flow

Once violations are near-zero:

```
ai-check --bundle default
ai-review
```

Still manual. No automation yet.

### Step 4.2 — CI Integration (Part VIII)

Only after stability. Belongs to Trigger Strategy.

---

## Phase 5 — ARCH_INDEX Hardening (Optional)

Once baseline is stable, enhance skill to validate:
- Every top-level module appears in ARCH_INDEX
- No undocumented modules exist
- No orphan directories exist
- Responsibility boundaries align

Converts ARCH_INDEX from documentation to enforcement anchor.
Do this gradually.

---

## Expected Order Per Repo

1. Add repo-local CLAUDE.md
2. Add minimal structural skill
3. Run manually
4. Fix drift
5. Stabilize
6. Enable enforcement
7. (Later) automate
8. (Later) tighten rules

Repeat for each repo before designing new-repo bootstrap.

---

## Acceptance Criteria (Per Repo)

- Repo-local CLAUDE.md exists and is authoritative
- Structural skill runs without false positives
- No major structural drift exists
- Codex review flow unchanged
- No CI regressions
- Architecture boundaries are explicit and enforceable

---

## Non-Goals

- Rewrite AGENTS.md into CLAUDE.md
- Delete ARCH_INDEX
- Introduce new skills beyond structural baseline
- Automate gating prematurely
- Change developer ergonomics during migration
