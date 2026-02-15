# AI tooling

This directory contains lightweight scripts and role prompts for AI-assisted development using Claude Code (with Codex CLI retained for review and patch workflows).

## Contents

- `CLAUDE.md`: Single constitutional authority loaded by all entrypoint scripts.
- `ai-chat.sh`: Starts an interactive Claude session with a selected role.
- `ai-plan.sh`: Starts Claude in read-only planner mode.
- `ai-review.sh`: Starts Codex in read-only reviewer mode.
- `ai-implement.sh`: Starts Claude Code with the implementer role.
- `ai-patch.sh`: Starts Codex in patcher mode for minimal diff emission.
- `install.sh`: Installs scripts, constitution, and role prompts into `~/.config/ai`.
- `deps.sh`: Installs Claude Code and Codex CLI if not already present.
- `roles/`: Role prompt files used by `ai-chat.sh`.
- `context/`: Optional context layers for supplementary prompt content.

## Requirements

- `claude` (Claude Code) for chat, plan, implement, and skill scripts.
- `codex` (OpenAI Codex CLI) for review and patch scripts.
- `jq` for JSON validation in `ai-skill.sh`.
- `yq` for YAML registry parsing in `ai-skill.sh`.
- `curl` if you want `deps.sh` to install Claude Code.
- `npm` if you want `deps.sh` to install Codex.

## Install

```sh
./ai/deps.sh      # installs claude and codex
./ai/install.sh
```

This copies scripts and role prompts into `~/.config/ai` and makes the scripts executable.

## Usage

Interactive chat with a role (default: architect):
```sh
~/.config/ai/ai-chat.sh [role]
```
Specialized entrypoints:
```sh
~/.config/ai/ai-plan.sh      # read-only task planning
~/.config/ai/ai-review.sh    # read-only code review
~/.config/ai/ai-implement.sh # Claude Code implementation session
~/.config/ai/ai-patch.sh     # Codex patcher for minimal diffs
```

- Default role is `architect` if none is provided.
- Roles must exist in `~/.config/ai/roles` (installed by `install.sh`).
- If you run the script directly from the repo without installing, it will not find roles in `~/.config/ai/roles`.

## Roles

Role prompts live in `roles/` and define behavior such as:

- `architect`: System design and tradeoff explanations.
- `planner`: Task breakdowns and sequencing (no file edits).
- `reviewer`: Code review with concrete issues.
- `implementer`: Precise edits when explicitly asked.
- `patch-architect`: Scoped change reasoning for narrow modifications (≤ 3 files).
- `patcher`: Minimal unified diff emission (Codex-targeted).

## How the prompt is assembled

Each entrypoint script builds a system prompt in this order:

1. Preamble (mode declaration, repo root).
2. `CLAUDE.md` — the constitutional authority.
3. Optional context layers from `~/.config/ai/context/*.md` (sorted).
4. The role prompt from `~/.config/ai/roles/`.
5. Repository `AGENTS.md` content (if present at repo root).
6. Repository `docs/ARCH_INDEX.md` content (if present).

This layered approach keeps constitutional rules sovereign while letting
roles and repository-specific guidance shape mode behavior.
