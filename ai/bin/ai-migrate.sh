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

echo "═══ ai-migrate ═══"
echo "Target: $TARGET"
echo

# ==========================================================================
# Phase A — Scan
# ==========================================================================

echo "▶ Phase A: Scanning repository..."

# Detect top-level directories
TOP_DIRS="$(ls -d "$TARGET"/*/ 2>/dev/null | xargs -I{} basename {} | sort)"
if [[ -n "$TOP_DIRS" ]]; then
  echo "  Directories: $(echo "$TOP_DIRS" | tr '\n' ' ')"
else
  echo "  No subdirectories found"
fi

# Detect languages/ecosystems
LANGUAGES=""
[[ -f "$TARGET/go.mod" ]] && LANGUAGES="${LANGUAGES}go "
[[ -f "$TARGET/package.json" ]] && LANGUAGES="${LANGUAGES}node "
[[ -f "$TARGET/pyproject.toml" ]] && LANGUAGES="${LANGUAGES}python "
[[ -f "$TARGET/Cargo.toml" ]] && LANGUAGES="${LANGUAGES}rust "
[[ -f "$TARGET/pom.xml" ]] && LANGUAGES="${LANGUAGES}java "
[[ -f "$TARGET/Gemfile" ]] && LANGUAGES="${LANGUAGES}ruby "

if [[ -n "$LANGUAGES" ]]; then
  echo "  Languages: $LANGUAGES"
else
  echo "  Languages: (none detected)"
fi

# Detect existing docs
EXISTING_DOCS=""
[[ -f "$TARGET/README.md" ]] && EXISTING_DOCS="${EXISTING_DOCS}README.md "
[[ -f "$TARGET/CLAUDE.md" ]] && EXISTING_DOCS="${EXISTING_DOCS}CLAUDE.md "
[[ -f "$TARGET/AGENTS.md" ]] && EXISTING_DOCS="${EXISTING_DOCS}AGENTS.md "

if [[ -n "$EXISTING_DOCS" ]]; then
  echo "  Existing docs: $EXISTING_DOCS"
else
  echo "  Existing docs: (none)"
fi
echo

# ==========================================================================
# Phase B — Repo CLAUDE.md
# ==========================================================================

echo "▶ Phase B: Repository CLAUDE.md"

CLAUDE_DST="$TARGET/CLAUDE.md"
if [[ -f "$CLAUDE_DST" ]]; then
  echo "  ✔ CLAUDE.md already exists"
  echo
  printf "  Review CLAUDE.md? [y/N] "
  read -r REPLY </dev/tty || REPLY="n"
  if [[ "$REPLY" == "y" ]] || [[ "$REPLY" == "Y" ]]; then
    echo "  --- Current CLAUDE.md (first 20 lines) ---"
    head -20 "$CLAUDE_DST" | sed 's/^/  /'
    echo "  ---"
  fi
else
  if [[ -f "$TEMPLATES_DIR/CLAUDE.md" ]]; then
    cp "$TEMPLATES_DIR/CLAUDE.md" "$CLAUDE_DST"
    echo "  ✔ Created CLAUDE.md from template"
    echo "  Review and customize for this repository"
  else
    echo "  ⚠ Template not found: $TEMPLATES_DIR/CLAUDE.md" >&2
    echo "  Create CLAUDE.md manually" >&2
  fi
fi
echo

# ==========================================================================
# Phase C — Scaffolds
# ==========================================================================

echo "▶ Phase C: Directory scaffolds"

# Create ai/ directories
for dir in ai/skills ai/baselines ai/out; do
  FULL_PATH="$TARGET/$dir"
  if [[ -d "$FULL_PATH" ]]; then
    echo "  ✔ $dir/ exists"
  else
    mkdir -p "$FULL_PATH"
    echo "  ✔ Created $dir/"
  fi
done

# Create repo-declared context channel (.ai/context/)
# Validators run by ai-skill / ai-check cannot read files at runtime, so the
# repository must mirror any orientation/contract sources it wants those
# validators to see into this directory. Entrypoints inject every *.md here
# verbatim after AGENTS.md.
CTX_DST="$TARGET/.ai/context"
if [[ -d "$CTX_DST" ]]; then
  echo "  ✔ .ai/context/ exists"
else
  mkdir -p "$CTX_DST"
  cat > "$CTX_DST/README.md" << 'CTX'
# Repo-declared context channel

Files in this directory are loaded verbatim (sorted by filename) into the
system prompt of every `ai/bin/ai-*` entrypoint, after `AGENTS.md`.

Use this channel to declare the repository's spine to non-interactive
validators (`ai-skill`, `ai-check`) that cannot read files at runtime.
Typical contents: an architecture index, contract excerpts, convention
sheets, module ownership maps, etc. The repo decides filenames and
contents — the loader makes no assumptions.

Delete this README once you populate the directory; it is informational.
CTX
  echo "  ✔ Created .ai/context/ with README"
fi

# Create repo-local skill scaffold
SKILL_DST="$TARGET/ai/skills/repo-convention-enforcer/v1"
if [[ -d "$SKILL_DST" ]]; then
  echo "  ✔ Skill scaffold already exists"
else
  SKILL_TEMPLATE="$TEMPLATES_DIR/skill"
  if [[ -d "$SKILL_TEMPLATE" ]]; then
    mkdir -p "$SKILL_DST"
    cp "$SKILL_TEMPLATE/SKILL.md" "$SKILL_DST/"
    cp "$SKILL_TEMPLATE/input.schema.json" "$SKILL_DST/"
    cp "$SKILL_TEMPLATE/output.schema.json" "$SKILL_DST/"
    echo "  ✔ Created skill scaffold: $SKILL_DST/"
  else
    echo "  ⚠ Skill template not found: $SKILL_TEMPLATE" >&2
  fi
fi

# Update .gitignore with ai/out/
GITIGNORE="$TARGET/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
  if ! grep -q 'ai/out/' "$GITIGNORE" 2>/dev/null; then
    echo "" >> "$GITIGNORE"
    echo "# AI governance runtime artifacts" >> "$GITIGNORE"
    echo "ai/out/" >> "$GITIGNORE"
    echo "  ✔ Added ai/out/ to .gitignore"
  else
    echo "  ✔ ai/out/ already in .gitignore"
  fi
else
  echo "ai/out/" > "$GITIGNORE"
  echo "  ✔ Created .gitignore with ai/out/"
fi
echo

# ==========================================================================
# Phase D — Baselines (optional)
# ==========================================================================

echo "▶ Phase D: Baselines"
printf "  Generate baseline snapshots? [y/N] "
read -r REPLY </dev/tty || REPLY="n"
if [[ "$REPLY" == "y" ]] || [[ "$REPLY" == "Y" ]]; then
  BASELINE_DIR="$TARGET/ai/baselines"
  mkdir -p "$BASELINE_DIR"

  # Directory listing baseline
  if [[ -n "$TOP_DIRS" ]]; then
    echo "$TOP_DIRS" > "$BASELINE_DIR/directories.txt"
    echo "  ✔ Saved directory listing to baselines/directories.txt"
  fi

  # File count baseline
  FILE_COUNT="$(find "$TARGET" -type f -not -path '*/.git/*' | wc -l | tr -d ' ')"
  echo "total_files: $FILE_COUNT" > "$BASELINE_DIR/metrics.yaml"
  echo "  ✔ Saved metrics baseline"
else
  echo "  Skipped"
fi
echo

# ==========================================================================
# Phase E — Validate
# ==========================================================================

echo "▶ Phase E: Validation"
echo

cd "$TARGET"
AI_CHECK="${SCRIPT_DIR}/ai-check.sh"
command -v ai-check >/dev/null 2>&1 && AI_CHECK="ai-check"

# Use --bundle default for migration validation (no diff context available,
# so --mode would skip all requires_diff skills and give a false pass)
"$AI_CHECK" --bundle default || echo "  ⚠ Validation completed with findings (review output above)"

# ==========================================================================
# Summary
# ==========================================================================

echo
echo "═══ Migration Complete ═══"
echo
echo "Next steps:"
echo "  1. Review and customize CLAUDE.md"
echo "  2. Populate .ai/context/ with any orientation/contract sources"
echo "     that validators (ai-skill / ai-check) must see inlined."
echo "  3. Review the repo-convention-enforcer skill"
echo "  4. Run: ai-check --mode NORMAL"
echo "  5. Fix any violations reported"
echo "  6. Commit governance artifacts"
