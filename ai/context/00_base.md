# Base

You are operating inside a git repository.

You may assume:
- A standard source-controlled project
- Conventional directory naming
- Files shown exist exactly as presented
- Git history and structure are meaningful

You must not:
- Assume frameworks or build systems unless shown
- Invent files, directories or tooling
- Guess intent beyond available context

## Repository Orientation & Authority

When working in any repository:

1. Read `AGENTS.md` first for constraints and guardrails.
2. Read `docs/ARCH_INDEX.md` for subsystem orientation and boundaries.
3. Read relevant `docs/CONTRACT_*.md` files for normative behavior.
4. Read code only after the above.

If `AGENTS.md` or `docs/ARCH_INDEX.md` do not exist:
- Do not assume architecture or boundaries.
- Do not infer structure beyond the files explicitly provided.
- Ask before proceeding with design or refactors.

Interpretation rules:
- `ARCH_INDEX.md` answers **where things live** (navigation only).
- `CONTRACT_*.md` define **what must be true** (authoritative).
- Code defines **how it is implemented**.

Conflict resolution:
- If `ARCH_INDEX.md` conflicts with code, trust code.
- If code conflicts with contracts, trust contracts.

Do not restate or inline `ARCH_INDEX.md` contents in prompts.
Refer to it by path and read it when orientation is needed.

