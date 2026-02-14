# Review Architecture

Tool separation policy for code review and structural validation.

---

## Tool Responsibilities

### Claude (Roles)

- Planning
- Architecture
- Implementation (scoped)
- Patch Architecture (scoped reasoning for narrow changes)
- No enforcement authority

### Claude Skills

- Structural validation
- Convention enforcement
- Schema-gated evaluation
- Deterministic JSON output
- CI-compatible exit codes

### Codex

- Patch emission (minimal diffs from architect plan)
- Code-level correctness
- API misuse
- Edge cases
- Language semantics
- Refactor safety
- Diff review

---

## Hard Rule

Claude Skills do not replace Codex review.

Codex review does not replace structural skill checks.

Both are required.

---

## Failure Semantics

- If any Claude Skill exits non-zero, the change must not proceed to Codex review.
- If Codex review fails, the change must not be merged even if Skills pass.
- Structural correctness is evaluated before semantic correctness.

---

## Boundary Clarification

Claude Skills evaluate:
- Repository structure
- File placement
- Naming conventions
- Architectural constraints
- Responsibility uniqueness
- Policy compliance defined in CLAUDE.md

Claude Skills do NOT evaluate:
- Runtime behavior
- Algorithmic correctness
- Performance characteristics
- Language-specific idioms

Codex evaluates:
- Syntax and semantic correctness
- API usage
- Logic errors
- Potential regressions
- Refactor safety

Codex does NOT enforce:
- Architectural philosophy
- Repository layout rules
- Convention policy

---

## Conflict Resolution

If a Claude Skill and Codex disagree:

1. Structural violations take precedence.
2. Code correctness issues take precedence over stylistic suggestions.
3. Human review is final authority.

---

## Two-Phase Edit Protocol

When a change request meets all criteria:
- Affects ≤ 3 files
- No directory changes
- No public API changes
- No new abstractions
- No module boundary changes

Use the patch workflow instead of full implementation.

### Phase 1 — Patch Architecture

Invoke Claude with `patch-architect.md`.

Output must contain:
- Files to modify
- Exact functions or regions
- Description of change
- Confirmation of no structural impact

Human must confirm plan.

### Phase 2 — Patch Emission

Invoke Codex with:
- Architect plan
- Only listed files
- `patcher.md` role

Codex emits unified diff only.

### Phase 3 — Structural Validation

Run:

```
./ai/ai-skill.sh repo-convention-enforcer
```

Must pass.

### Phase 4 — Codex Review (Full)

Run:

```
./ai/ai-review.sh
```

Must pass.

---

## Recommended PR Flow

1. Run structural validation:

   ```
   ./ai/ai-skill.sh repo-convention-enforcer
   ```

2. If exit code 0, run tactical code review:

   ```
   ./ai/ai-review.sh
   ```

Automation of this flow belongs in Part VIII (Trigger Strategy).
