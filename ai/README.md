# AI tooling

This directory contains lightweight scripts and role prompts for AI-assisted development using Claude Code (with Codex CLI retained for the reviewer).

## Contents

- `ai-chat.sh`: Starts an interactive Claude session with a selected role.
- `ai-plan.sh`: Starts Claude in read-only planner mode.
- `ai-review.sh`: Starts Codex in read-only reviewer mode.
- `ai-implement.sh`: Starts Claude Code with the implementer role.
- `install.sh`: Installs scripts and role prompts into `~/.config/ai`.
- `deps.sh`: Installs Claude Code and Codex CLI if not already present.
- `roles/`: Role prompt files used by `ai-chat.sh`.
- `context/`: Shared context snippets included in prompts.

## Requirements

- `claude` (Claude Code) for chat, plan, and implement scripts.
- `codex` (OpenAI Codex CLI) for the review script.
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

## How the prompt is assembled

`ai-chat.sh` builds a prompt that includes:

1. Context files from `~/.config/ai/context` (global rules and conventions).
2. The selected role prompt from `~/.config/ai/roles`.
3. Repository `AGENTS.md` content if it exists at the current repo root.

This layered approach keeps role behavior consistent while letting repository‑specific guidance shape responses.
