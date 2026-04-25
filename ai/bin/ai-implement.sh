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

command -v claude >/dev/null || { echo "claude not found"; exit 1; }

CLAUDE_FILE="$AI_DIR/CLAUDE.md"
CTX_DIR="$AI_DIR/context"
ROLE_DIR="$AI_DIR/roles"
OUT_DIR="$AI_DIR/out"
MAX_ITERATIONS=3

# Detect repo root (fallback to current dir)
REPO_ROOT="$PWD"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi

# ==========================================================================
# Preflight
# ==========================================================================

# Hard-fail if on main/master
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
  echo "✖ error: refusing to implement on '$CURRENT_BRANCH'" >&2
  echo "  hint: create a worktree first:" >&2
  echo "    git worktree add -b <branch> ../<repo>-<suffix> $CURRENT_BRANCH" >&2
  exit 1
fi

# Warn if in main worktree (not a git worktree)
if ! git rev-parse --git-common-dir >/dev/null 2>&1 || \
   [[ "$(git rev-parse --git-common-dir 2>/dev/null)" == "$(git rev-parse --git-dir 2>/dev/null)" ]]; then
  echo "⚠ warning: working in main worktree, not a git worktree" >&2
  echo "  hint: git worktree add -b $CURRENT_BRANCH ../<repo>-<suffix> main" >&2
  echo
fi

# Detect merge base: main → master → origin/main → origin/master
MERGE_BASE=""
for candidate in main master origin/main origin/master; do
  if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
    MERGE_BASE="$(git merge-base "$candidate" HEAD 2>/dev/null || echo "")"
    [[ -n "$MERGE_BASE" ]] && break
  fi
done

if [[ -z "$MERGE_BASE" ]]; then
  echo "⚠ warning: could not determine merge base (no main/master found)" >&2
  echo "  governance gating will be skipped" >&2
fi

# Consume plan.json if present
PLAN_INTENT=""
# NOTE: PLAN_CONSTRAINTS is parsed and preserved for future enforcement
# (allow_new_files, allow_moves, allowed_files, etc.). Currently used only
# for intent-based mode hinting. Constraint enforcement is deferred to v2
# when paths_any/flags_any predicates are wired into ai-check routing.
PLAN_CONSTRAINTS=""
PLAN_FILE="$OUT_DIR/plan.json"
if [[ -f "$PLAN_FILE" ]]; then
  echo "▶ Consuming plan.json"
  PLAN_INTENT="$(jq -r '.intent // ""' "$PLAN_FILE" 2>/dev/null || echo "")"
  PLAN_CONSTRAINTS="$(jq -c '.constraints // {}' "$PLAN_FILE" 2>/dev/null || echo "{}")"
  mv "$PLAN_FILE" "$OUT_DIR/plan.consumed.json" 2>/dev/null || true
fi

# ==========================================================================
# Resolve ai-check command
# ==========================================================================
AI_CHECK="${SCRIPT_DIR}/ai-check.sh"
command -v ai-check >/dev/null 2>&1 && AI_CHECK="ai-check"

# ==========================================================================
# Diff profiling
# ==========================================================================

compute_diff_profile() {
  local base="$1"

  local diff_output
  diff_output="$(git diff "$base" 2>/dev/null || echo "")"
  local stat_output
  stat_output="$(git diff --stat "$base" 2>/dev/null || echo "")"
  local name_status
  name_status="$(git diff --name-status "$base" 2>/dev/null || echo "")"
  local diff_names
  diff_names="$(git diff --name-only "$base" 2>/dev/null || echo "")"

  # Include untracked files (git diff never shows these)
  local untracked
  untracked="$(git -C "$REPO_ROOT" ls-files --others --exclude-standard 2>/dev/null || echo "")"
  if [[ -n "$untracked" ]]; then
    if [[ -n "$diff_names" ]]; then
      diff_names="$(printf '%s\n%s' "$diff_names" "$untracked" | sort -u)"
    else
      diff_names="$untracked"
    fi
    # Untracked files are new files — append to name_status as additions
    local untracked_status
    untracked_status="$(echo "$untracked" | sed 's/^/A\t/')"
    if [[ -n "$name_status" ]]; then
      name_status="$(printf '%s\n%s' "$name_status" "$untracked_status")"
    else
      name_status="$untracked_status"
    fi
  fi

  local files_changed=0
  local new_files=0
  local renames=0
  local lines_added=0
  local lines_removed=0
  local diff_lines=0

  if [[ -n "$diff_names" ]]; then
    files_changed="$(echo "$diff_names" | wc -l | tr -d ' ')"
  fi

  if [[ -n "$name_status" ]]; then
    new_files="$(echo "$name_status" | grep -c '^A' || echo 0)"
    renames="$(echo "$name_status" | grep -c '^R' || echo 0)"
  fi

  if [[ -n "$diff_output" ]]; then
    lines_added="$(echo "$diff_output" | grep -c '^+[^+]' || echo 0)"
    lines_removed="$(echo "$diff_output" | grep -c '^-[^-]' || echo 0)"
    diff_lines="$(echo "$diff_output" | wc -l | tr -d ' ')"
  fi

  # Top-level directories touched
  local top_level_dirs=""
  if [[ -n "$diff_names" ]]; then
    top_level_dirs="$(echo "$diff_names" | sed 's|/.*||' | sort -u | jq -R . | jq -sc .)"
  else
    top_level_dirs="[]"
  fi

  # Public surface paths (api/, sdk/, public/, cmd/, cli/)
  local public_surface_paths="[]"
  if [[ -n "$diff_names" ]]; then
    local ps
    ps="$(echo "$diff_names" | grep -E '^(api/|sdk/|public/|cmd/|cli/)' || echo "")"
    if [[ -n "$ps" ]]; then
      public_surface_paths="$(echo "$ps" | jq -R . | jq -sc .)"
    fi
  fi

  # Structural detection: control plane paths
  local has_structural=false
  if [[ -n "$diff_names" ]]; then
    if echo "$diff_names" | grep -qE '(control/|orchestrator/|state_machine/|persistence/|auth/)'; then
      has_structural=true
    fi
  fi

  # Full file list for predicate routing
  local changed_files="[]"
  if [[ -n "$diff_names" ]]; then
    changed_files="$(echo "$diff_names" | jq -R . | jq -sc .)"
  fi

  jq -n \
    --argjson files_changed "$files_changed" \
    --argjson new_files "$new_files" \
    --argjson renames "$renames" \
    --argjson lines_added "$lines_added" \
    --argjson lines_removed "$lines_removed" \
    --argjson diff_lines "$diff_lines" \
    --argjson top_level_dirs "$top_level_dirs" \
    --argjson public_surface_paths "$public_surface_paths" \
    --argjson has_structural "$has_structural" \
    --argjson changed_files "$changed_files" \
    '{
      files_changed: $files_changed,
      new_files: $new_files,
      renames: $renames,
      lines_added: $lines_added,
      lines_removed: $lines_removed,
      diff_lines: $diff_lines,
      top_level_dirs: $top_level_dirs,
      public_surface_paths: $public_surface_paths,
      has_structural: $has_structural,
      changed_files: $changed_files
    }'
}

# ==========================================================================
# Mode determination (precedence cascade)
# ==========================================================================

determine_mode() {
  local profile_json="$1"
  local plan_intent="${2:-}"

  local diff_lines files_changed new_files renames has_structural
  local top_dirs_count public_paths_count

  diff_lines="$(echo "$profile_json" | jq '.diff_lines')"
  files_changed="$(echo "$profile_json" | jq '.files_changed')"
  new_files="$(echo "$profile_json" | jq '.new_files')"
  renames="$(echo "$profile_json" | jq '.renames')"
  has_structural="$(echo "$profile_json" | jq -r '.has_structural')"
  top_dirs_count="$(echo "$profile_json" | jq '.top_level_dirs | length')"
  public_paths_count="$(echo "$profile_json" | jq '.public_surface_paths | length')"

  # 1. HEAVY if diff_lines > 500 OR files > 15 OR (structural AND api)
  if [[ "$diff_lines" -gt 500 ]] || [[ "$files_changed" -gt 15 ]]; then
    echo "HEAVY"; return
  fi
  if [[ "$has_structural" == "true" ]] && [[ "$public_paths_count" -gt 0 ]]; then
    echo "HEAVY"; return
  fi

  # 2. STRUCTURAL if top-level dirs changed (>1) OR renames/moves
  if [[ "$top_dirs_count" -gt 1 ]] || [[ "$renames" -gt 0 ]]; then
    echo "STRUCTURAL"; return
  fi

  # 3. API if public surface paths touched
  if [[ "$public_paths_count" -gt 0 ]]; then
    echo "API"; return
  fi

  # 4. PATCH if plan says patch OR (≤3 files, no new files, no renames)
  if [[ "$plan_intent" == "patch" ]]; then
    echo "PATCH"; return
  fi
  if [[ "$files_changed" -le 3 ]] && [[ "$new_files" -eq 0 ]] && [[ "$renames" -eq 0 ]]; then
    echo "PATCH"; return
  fi

  # 5. NORMAL (default)
  echo "NORMAL"
}

# ==========================================================================
# Build system prompt
# ==========================================================================

build_system_prompt() {
  local extra_context="${1:-}"

  echo "You are an AI assistant engaged in an interactive technical conversation."
  echo "Follow the role definition exactly."
  echo
  echo "Repository root: $REPO_ROOT"
  echo

  echo "You are operating in IMPLEMENTER mode."
  echo

  cat "$CLAUDE_FILE"
  echo

  while IFS= read -r -d '' f; do
    cat "$f"
    echo
  done < <(find "$CTX_DIR" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null | LC_ALL=C sort -z)
  cat "$ROLE_DIR/implementer.md"

  if [[ -f "$REPO_ROOT/AGENTS.md" ]]; then
    echo
    echo "Repository context:"
    cat "$REPO_ROOT/AGENTS.md"
  fi

  # Repo-declared context layers (orientation, contracts, etc.).
  # The repo populates .ai/context/*.md to declare its own spine.
  while IFS= read -r -d '' f; do
    echo
    echo "Repo-declared context ($(basename "$f")):"
    cat "$f"
  done < <(find "$REPO_ROOT/.ai/context" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null | LC_ALL=C sort -z)

  if [[ -n "$extra_context" ]]; then
    echo
    echo "═══ Previous governance findings (fix these) ═══"
    echo "$extra_context"
  fi
}

# ==========================================================================
# Gating loop
# ==========================================================================

mkdir -p "$OUT_DIR"
ITERATION=0
FINDINGS_CONTEXT=""

while [[ "$ITERATION" -lt "$MAX_ITERATIONS" ]]; do
  ITERATION=$((ITERATION + 1))

  # --- SESSION phase -------------------------------------------------------
  echo
  echo "═══ Implementation session (iteration $ITERATION/$MAX_ITERATIONS) ═══"
  echo

  SYSTEM_PROMPT="$(build_system_prompt "$FINDINGS_CONTEXT")"

  # Invoke claude without exec so script continues after session
  # || true because user ctrl-C gives non-zero
  claude --system-prompt "$SYSTEM_PROMPT" "$@" || true

  # --- CAPTURE_DIFF phase --------------------------------------------------
  if [[ -z "$MERGE_BASE" ]]; then
    echo
    echo "⚠ No merge base — skipping governance gating"
    echo "✔ Session complete (ungated)"
    exit 0
  fi

  # Check if there are any changes at all (tracked + untracked)
  DIFF_CHECK="$(git diff --name-only "$MERGE_BASE" 2>/dev/null || echo "")"
  UNTRACKED_CHECK="$(git -C "$REPO_ROOT" ls-files --others --exclude-standard 2>/dev/null || echo "")"
  if [[ -z "$DIFF_CHECK" ]] && [[ -z "$UNTRACKED_CHECK" ]]; then
    echo
    echo "⚠ No changes detected from merge base — skipping gating"
    echo "✔ Session complete (no changes)"
    exit 0
  fi

  # --- PROFILE phase -------------------------------------------------------
  echo
  echo "▶ Computing diff profile..."
  PROFILE_JSON="$(compute_diff_profile "$MERGE_BASE")"

  # --- MODE phase ----------------------------------------------------------
  MODE="$(determine_mode "$PROFILE_JSON" "$PLAN_INTENT")"
  echo "▶ Determined mode: $MODE"
  echo "  Profile: $(echo "$PROFILE_JSON" | jq -c '{files: .files_changed, lines: .diff_lines, new: .new_files, renames: .renames}')"

  # --- GATE phase ----------------------------------------------------------
  echo
  echo "═══ Running governance gate (mode: $MODE) ═══"
  echo

  GATE_EXIT=0
  "$AI_CHECK" --mode "$MODE" --fail-fast --base "$MERGE_BASE" --diff-profile "$PROFILE_JSON" || GATE_EXIT=$?

  if [[ "$GATE_EXIT" -eq 0 ]]; then
    # --- PASS: blessed ---
    echo
    echo "✔ Governance gate passed (mode: $MODE)"

    # Save artifacts
    git diff "$MERGE_BASE" > "$OUT_DIR/last.patch" 2>/dev/null || true
    if [[ -f "$OUT_DIR/ai-check.json" ]]; then
      cp "$OUT_DIR/ai-check.json" "$OUT_DIR/last.report.json"
    fi

    exit 0
  fi

  # --- FAIL ---
  echo
  echo "✖ Governance gate failed (mode: $MODE)"

  if [[ "$ITERATION" -ge "$MAX_ITERATIONS" ]]; then
    echo
    echo "✖ Max iterations ($MAX_ITERATIONS) reached — dumping findings" >&2
    if [[ -f "$OUT_DIR/ai-check.json" ]]; then
      jq -r '.results[] | select(.exit_code != 0) | "  ✖ \(.name): blocking=\(.blocking) major=\(.major)"' "$OUT_DIR/ai-check.json" 2>/dev/null || true
    fi
    exit 1
  fi

  # Prompt user to re-enter
  echo
  printf "Re-enter session to fix findings? [y/N] "
  read -r REPLY </dev/tty || REPLY="n"
  if [[ "$REPLY" != "y" ]] && [[ "$REPLY" != "Y" ]]; then
    echo "Changes remain in working tree (not blessed)"
    exit 1
  fi

  # Build findings context for next iteration
  FINDINGS_CONTEXT=""
  if [[ -f "$OUT_DIR/ai-check.json" ]]; then
    FINDINGS_CONTEXT="$(jq -r '
      .results[]
      | select(.exit_code != 0)
      | "SKILL: \(.name) | blocking: \(.blocking) | major: \(.major) | warning: \(.warning)"
    ' "$OUT_DIR/ai-check.json" 2>/dev/null || echo "")"
  fi

  # Clear extra args for re-entry (don't pass user's original args twice in prompt)
  shift $# 2>/dev/null || true
done
