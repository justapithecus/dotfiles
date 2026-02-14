# Review Architecture

Tool separation policy for code review and structural validation.

---

## Tool Responsibilities

### Claude (Roles)

- Planning
- Architecture
- Implementation (scoped)
- No enforcement authority

### Claude Skills

- Structural validation
- Convention enforcement
- Schema-gated evaluation
- Deterministic JSON output
- CI-compatible exit codes

### Codex

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
