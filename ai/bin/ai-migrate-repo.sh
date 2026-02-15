#!/usr/bin/env bash
set -euo pipefail

# Portable script directory resolution (no readlink -f dependency)
SCRIPT_DIR="$(
  src="${BASH_SOURCE[0]}"
  while [[ -L "$src" ]]; do
    dir="$(cd "$(dirname "$src")" && pwd -P)"
    src="$(readlink "$src")"
    [[ "$src" != /* ]] && src="$dir/$src"
  done
  cd "$(dirname "$src")" && pwd -P
)"

# Resolve AI_DIR: env override > repo-relative parent > install breadcrumb
if [[ -n "${AI_DIR:-}" ]] && [[ -f "$AI_DIR/CLAUDE.md" ]]; then
  : # caller-provided AI_DIR
elif [[ -f "$SCRIPT_DIR/../CLAUDE.md" ]]; then
  AI_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [[ -f "$SCRIPT_DIR/.ai-source" ]]; then
  AI_DIR="$(cat "$SCRIPT_DIR/.ai-source")"
else
  echo "error: cannot locate ai/ directory. Set AI_DIR or reinstall." >&2
  exit 1
fi
TEMPLATES_DIR="$AI_DIR/templates/migration"

# --- Parse arguments ------------------------------------------------------

TARGET="${1:-$PWD}"

if [[ ! -d "$TARGET" ]]; then
  echo "error: directory not found: $TARGET" >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

echo "═══ ai-migrate-repo ═══"
echo "Target: $TARGET"
echo

# --- Step 1: Create repo CLAUDE.md ----------------------------------------

CLAUDE_DST="$TARGET/CLAUDE.md"
if [[ -f "$CLAUDE_DST" ]]; then
  echo "✔ CLAUDE.md already exists (skipping)"
else
  if [[ -f "$TEMPLATES_DIR/CLAUDE.md" ]]; then
    cp "$TEMPLATES_DIR/CLAUDE.md" "$CLAUDE_DST"
    echo "✔ Created CLAUDE.md from template"
  else
    echo "⚠ Template not found: $TEMPLATES_DIR/CLAUDE.md" >&2
    echo "  Create CLAUDE.md manually" >&2
  fi
fi

# --- Step 2: Create repo-local skill scaffold -----------------------------

SKILL_DST="$TARGET/ai/skills/repo-convention-enforcer/v1"
if [[ -d "$SKILL_DST" ]]; then
  echo "✔ Skill scaffold already exists (skipping)"
else
  SKILL_TEMPLATE="$TEMPLATES_DIR/skill"
  if [[ -d "$SKILL_TEMPLATE" ]]; then
    mkdir -p "$SKILL_DST"
    cp "$SKILL_TEMPLATE/SKILL.md" "$SKILL_DST/"
    cp "$SKILL_TEMPLATE/input.schema.json" "$SKILL_DST/"
    cp "$SKILL_TEMPLATE/output.schema.json" "$SKILL_DST/"
    echo "✔ Created skill scaffold: $SKILL_DST/"
  else
    echo "⚠ Skill template not found: $SKILL_TEMPLATE" >&2
  fi
fi

# --- Step 3: Scaffold docs/ARCH_INDEX.md ----------------------------------

ARCH_CANDIDATES=("$TARGET/docs/ARCH_INDEX.md" "$TARGET/ARCH_INDEX.md")
ARCH_EXISTS=false
for candidate in "${ARCH_CANDIDATES[@]}"; do
  if [[ -f "$candidate" ]]; then
    ARCH_EXISTS=true
    echo "✔ ARCH_INDEX.md already exists: $candidate"
    break
  fi
done

if [[ "$ARCH_EXISTS" == "false" ]]; then
  mkdir -p "$TARGET/docs"
  cat > "$TARGET/docs/ARCH_INDEX.md" << 'ARCH'
# ARCH_INDEX.md — Architecture Index

This file is a fast lookup table for agents opening this repository.
It summarizes what exists and where, not how things are implemented.

---

## Root

- `ARCH_INDEX.md` — this file (or `docs/ARCH_INDEX.md`)
- `README.md` — repository overview
- `CLAUDE.md` — repository constitution

---

<!-- Add sections for each top-level directory -->
ARCH
  echo "✔ Scaffolded docs/ARCH_INDEX.md"
fi

# --- Step 4: Run ai-check ------------------------------------------------

echo
echo "═══ Running ai-check --bundle default ═══"
echo

cd "$TARGET"
AI_CHECK="${SCRIPT_DIR}/ai-check.sh"
command -v ai-check >/dev/null 2>&1 && AI_CHECK="ai-check"
"$AI_CHECK" --bundle default || true

# --- Next steps -----------------------------------------------------------

echo
echo "═══ Next Steps ═══"
echo "  1. Review and customize CLAUDE.md for this repository"
echo "  2. Review and customize the repo-convention-enforcer skill"
echo "  3. Update docs/ARCH_INDEX.md with actual directory structure"
echo "  4. Run: ai-check --bundle default"
echo "  5. Fix any violations reported"
echo "  6. See: ai/MIGRATION.md for the full migration protocol"
