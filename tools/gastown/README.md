# gastown

Durable artifact system for curated AI work products.

Artifacts live at `$GASTOWN_HOME` (default: `~/workspace/gastown`).

## Structure

- `towns/` — named artifact collections
- `conversations/` — conversation-level exports
- `fragments/` — reusable pieces and partials
- `scratch/` — temporary working space

## How it differs from ai/tools/

`ai/tools/` contains agent-built tools that operate during live sessions.
gastown manages curated artifacts and does not observe or intercept live agent interaction.

## Setup

```sh
source tools/gastown/env.sh   # defines GASTOWN_HOME
bash tools/gastown/install.sh  # creates the directory structure
```

Installation is explicit. Nothing runs automatically on shell startup.
