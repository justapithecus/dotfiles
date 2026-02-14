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
