# Dotfiles

Personal dotfiles plus an AI‑augmented development environment designed to
improve itself over time.

---

## Start Here (for Agents)

Agents opening this repository should read:

1. [`ARCH_INDEX.md`](./ARCH_INDEX.md)
2. `ai/` (especially `roles/`, `context/`, and `AGENTS.md` if present)

---

## Repository Layout

```
dotfiles/
├── ai/          # AI substrate
├── shell/       # Shell configuration
├── editor/      # Editor configuration
├── terminal/    # Terminal config
├── scripts/     # Human utilities
├── fonts/       # Font assets
└── ...
```

---

## The `ai/` Directory

The `ai/` directory is the core of the repo.

It contains:
- cognitive roles
- persistent context
- prompt composition
- agent‑built tools

This directory is expected to change frequently.

---

## Stability Model

- `shell/`, `editor/`, `terminal/` — stable
- `scripts/` — semi‑stable
- `ai/` — intentionally unstable

---

## Architectural Guidance

- Architectural navigation: [`ARCH_INDEX.md`](./ARCH_INDEX.md)
- AI behavior and constraints: `ai/`

---

Optimized for leverage over polish.
