# ARCH_INDEX.md — Dotfiles Architecture Index

This file is a **fast lookup table for agents** opening this repository.
It summarizes *what exists and where*, not how things are implemented.

This file is intentionally **self-referential**:
Agents are instructed (via `ai/`) to look for this file first.

Normative behavior for AI usage is defined under `ai/`.
Shell, editor, and terminal behavior is defined by their respective configs.

Maintenance rule:
- Update this file only when a new directory boundary or responsibility becomes real.
- Do not update for internal refactors, prompt tweaks, or tool iteration.

---

## Root

- `ARCH_INDEX.md` — architectural navigation index (this file)
- `CLAUDE.md` — repo-local constitution (dotfiles-specific)
- `AGENTS.md` — behavioral expectations (also read by Codex)
- `README.md` — repository overview and navigational entrypoint
- `.gitignore` — git exclusions
- miscellaneous dotfiles — tool- or editor-specific entrypoints

---

## ai/

**AI substrate. This is the highest‑leverage directory in the repo.**

Purpose:
- prompt composition
- role separation
- persistent context
- agent-built tools
- recursive bootstrapping

Agents should treat this directory as authoritative.

Contents:
- `CLAUDE.md` — single constitutional authority for all AI sessions
- `bin/` — executable entrypoint scripts (ai-chat, ai-check, ai-skill, etc.)
- `roles/` — cognitive role definitions (planner, implementer, reviewer, etc.)
- `skills/` — skill definitions with SKILL.md + schema contracts (7 skills)
- `completion/` — shell completion scripts
- `out/` — runtime artifacts from ai-check runs (gitignored)
- `context/` — optional context layers for supplementary prompt content
- `templates/` — migration scaffolds for onboarding new repos

Stability:
- Intentionally unstable
- Expected to evolve rapidly
- Contracts matter more than code

---

## shell/

Shell configuration and environment wiring.

Rules:
- No agent semantics
- No prompt logic
- Execution only

---

## scripts/

Human-facing utilities.

Rule:
If a script exists primarily to improve AI workflows or parse agent output,
it belongs in `ai/tools/`, not here.

---

## editor/

Editor configuration (Neovim, Helix, etc.).

---

## terminal/

Terminal emulator configuration.

---

## fonts/

Font assets used by terminal or editor configurations.

---

## tools/

Standalone tooling that lives outside the AI substrate.

Contents:
- `gastown/` — installer and env wiring for [Gas Town](https://github.com/steveyegge/gastown) multi-agent workspace manager

Rules:
- Installation is explicit and user-controlled
- Each tool manages its own install script and env integration

---

## Architectural Notes

- This repository is a **personal computing substrate**, not a product
- `ai/` evolves faster than all other directories
- Leverage > polish
- Repo splits occur only when pressure exists

This index is intentionally stable and low-detail.
