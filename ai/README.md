# AI tooling

This directory contains lightweight scripts and role prompts for the OpenAI Codex CLI, focused on starting role‑specific interactive sessions.

## Contents

- `ai-chat.sh`: Starts an interactive Codex session with a selected role prompt.
- `install.sh`: Installs scripts and role prompts into `~/.config/ai`.
- `deps.sh`: Installs the Codex CLI (via npm) if it is not already present.
- `roles/`: Role prompt files used by `ai-chat.sh`.
- `context/`: Shared context snippets (not currently used by the scripts here).

## Requirements

- `codex` binary (OpenAI Codex CLI).
- `npm` if you want `deps.sh` to install Codex for you.

## Install

```sh
./ai/deps.sh
./ai/install.sh
```

This copies scripts and role prompts into `~/.config/ai` and makes the scripts executable.

## Usage

```sh
~/.config/ai/ai-chat.sh [role]
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

1. A fixed preamble (interaction rules).
2. The selected role prompt from `~/.config/ai/roles`.
3. Repository `AGENTS.md` content if it exists at the current repo root.

This keeps role behavior consistent while letting repository‑specific guidance shape responses.
