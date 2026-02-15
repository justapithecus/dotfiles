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

# --- Preflight ------------------------------------------------------------

command -v yq >/dev/null 2>&1 || {
  echo "error: yq not found" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || {
  echo "error: jq not found" >&2
  exit 1
}

# --- Parse arguments ------------------------------------------------------

BUNDLE="default"
MODE=""
SCOPE=""
BASE_REF=""
DIFF_PROFILE=""
FAIL_FAST=false
BUNDLE_SET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle)
      [[ $# -ge 2 ]] || { echo "error: --bundle requires a value" >&2; exit 1; }
      BUNDLE="$2"; BUNDLE_SET=true; shift 2 ;;
    --mode)
      [[ $# -ge 2 ]] || { echo "error: --mode requires a value" >&2; exit 1; }
      MODE="$2"; shift 2 ;;
    --diff-profile)
      # JSON diff profile from ai-implement. Enables predicate filtering
      # (paths_any/flags_any) when combined with --mode routing.
      [[ $# -ge 2 ]] || { echo "error: --diff-profile requires a value" >&2; exit 1; }
      DIFF_PROFILE="$2"; shift 2 ;;
    --scope)
      [[ $# -ge 2 ]] || { echo "error: --scope requires a value" >&2; exit 1; }
      SCOPE="$2"; shift 2 ;;
    --base)
      [[ $# -ge 2 ]] || { echo "error: --base requires a value" >&2; exit 1; }
      BASE_REF="$2"; shift 2 ;;
    --fail-fast)
      FAIL_FAST=true; shift ;;
    -h|--help)
      echo "usage: ai-check [--bundle <name>|--mode <MODE>] [--scope path,...] [--base <ref>] [--fail-fast]"
      echo
      echo "Modes: PATCH, NORMAL, STRUCTURAL, API, HEAVY, AUDIT"
      echo
      echo "Bundles:"
      yq e '.bundles | keys | .[]' "$AI_DIR/skills.yaml" 2>/dev/null | sed 's/^/  /'
      exit 0 ;;
    *)
      echo "error: unknown argument: $1" >&2; exit 1 ;;
  esac
done

# Mutual exclusion: --mode and --bundle cannot both be explicitly set
if [[ -n "$MODE" ]] && [[ "$BUNDLE_SET" == "true" ]]; then
  echo "error: --mode and --bundle are mutually exclusive" >&2
  exit 1
fi

# Validate --mode value
if [[ -n "$MODE" ]]; then
  case "$MODE" in
    PATCH|NORMAL|STRUCTURAL|API|HEAVY|AUDIT) ;;
    *) echo "error: invalid mode '$MODE' (valid: PATCH, NORMAL, STRUCTURAL, API, HEAVY, AUDIT)" >&2; exit 1 ;;
  esac
fi

# --- Predicate evaluation -------------------------------------------------

evaluate_predicates() {
  local skill_name="$1"
  local profile_json="$2"

  # Extract predicates from registry
  local paths_any flags_any
  paths_any="$(yq e -o=json ".registry[] | select(.name == \"$skill_name\") | .run_when.paths_any // []" "$REGISTRY")"
  flags_any="$(yq e -o=json ".registry[] | select(.name == \"$skill_name\") | .run_when.flags_any // []" "$REGISTRY")"

  local has_paths has_flags
  has_paths="$(echo "$paths_any" | jq 'length > 0')"
  has_flags="$(echo "$flags_any" | jq 'length > 0')"

  # No predicates = always match
  if [[ "$has_paths" != "true" ]] && [[ "$has_flags" != "true" ]]; then
    return 0
  fi

  # paths_any: any changed file matches any glob pattern
  if [[ "$has_paths" == "true" ]]; then
    local match
    match="$(echo "$profile_json" | jq -r --argjson patterns "$paths_any" '
      .changed_files // [] | . as $files |
      any($files[]; . as $f |
        any($patterns[]; . as $pat |
          ($pat | gsub("\\*\\*"; "DBLSTAR") | gsub("\\*"; "[^/]*") | gsub("DBLSTAR"; ".*") | gsub("\\?"; "[^/]"))
          | . as $re | ($f | test("^" + $re + "$"))
        )
      )
    ')"
    [[ "$match" == "true" ]] && return 0
  fi

  # flags_any: any flag condition is true
  if [[ "$has_flags" == "true" ]]; then
    local match
    match="$(echo "$profile_json" | jq -r --argjson flags "$flags_any" '
      . as $profile |
      any($flags[]; . as $flag |
        if ($flag | test("\\s*[><=!]+\\s*")) then
          ($flag | capture("^(?<field>\\w+)\\s*(?<op>[><=!]+)\\s*(?<val>.+)$")) as $p |
          ($profile[$p.field] // 0) as $actual | ($p.val | tonumber) as $thr |
          if $p.op == ">"  then $actual > $thr
          elif $p.op == ">=" then $actual >= $thr
          elif $p.op == "<"  then $actual < $thr
          elif $p.op == "<=" then $actual <= $thr
          elif $p.op == "==" then $actual == $thr
          else false end
        else
          $profile[$flag] // false |
          if type == "boolean" then . elif type == "number" then . > 0 else false end
        end
      )
    ')"
    [[ "$match" == "true" ]] && return 0
  fi

  return 1
}

# --- Resolve skill set ----------------------------------------------------

REGISTRY="$AI_DIR/skills.yaml"
if [[ ! -f "$REGISTRY" ]]; then
  echo "error: registry not found: $REGISTRY" >&2
  exit 1
fi

SOURCE=""

if [[ -n "$MODE" ]]; then
  # --- Mode-based routing: select skills by run_when.modes ----------------
  # Sort: cheap→moderate→heavy, then deterministic→heuristic→semantic
  COST_ORDER='{"cheap":0,"moderate":1,"heavy":2}'
  MODE_ORDER='{"deterministic":0,"heuristic":1,"semantic":2}'
  ORDERED_SKILLS="$(yq e -o=json '.registry' "$REGISTRY" \
    | jq -r --arg mode "$MODE" --argjson cost_order "$COST_ORDER" --argjson mode_order "$MODE_ORDER" '
      [.[] | select(.run_when.modes // [] | index($mode))]
      | sort_by($cost_order[.cost] // 99, $mode_order[.mode] // 99)
      | .[].name
    ')"
  if [[ -z "$ORDERED_SKILLS" ]]; then
    echo "error: no skills matched mode '$MODE'" >&2
    exit 1
  fi
  SOURCE="mode:$MODE"
else
  # --- Bundle-based routing (original behavior) ---------------------------
  BUNDLE_SKILLS="$(yq e ".bundles.$BUNDLE[]" "$REGISTRY" 2>/dev/null)"
  if [[ -z "$BUNDLE_SKILLS" ]] || [[ "$BUNDLE_SKILLS" == "null" ]]; then
    echo "error: bundle '$BUNDLE' not found in registry" >&2
    echo "Available bundles:" >&2
    yq e '.bundles | keys | .[]' "$REGISTRY" | sed 's/^/  /' >&2
    exit 1
  fi
  # Bundle listing order is authoritative. The bundle author controls
  # execution sequence intentionally (e.g., gate skills first).
  ORDERED_SKILLS="$BUNDLE_SKILLS"
  SOURCE="bundle:$BUNDLE"
fi

# --- Create output directory ----------------------------------------------

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$AI_DIR/out/$TIMESTAMP"
mkdir -p "$OUT_DIR"

# --- Resolve ai-skill command ---------------------------------------------

AI_SKILL="${SCRIPT_DIR}/ai-skill.sh"
command -v ai-skill >/dev/null 2>&1 && AI_SKILL="ai-skill"

# --- Run skills -----------------------------------------------------------

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0
BLOCKING_FAILED=0
SKILL_RESULTS_JSON="[]"

while IFS= read -r skill_name; do
  [[ -n "$skill_name" ]] || continue
  TOTAL=$((TOTAL + 1))

  # Check registry metadata
  IS_MANDATORY="$(yq e ".registry[] | select(.name == \"$skill_name\") | .mandatory" "$REGISTRY")"
  SKILL_COST="$(yq e ".registry[] | select(.name == \"$skill_name\") | .cost" "$REGISTRY")"
  REQUIRES_DIFF="$(yq e ".registry[] | select(.name == \"$skill_name\") | .requires_diff" "$REGISTRY")"
  if [[ "$REQUIRES_DIFF" == "null" ]] || [[ -z "$REQUIRES_DIFF" ]]; then
    REQUIRES_DIFF="$(yq e '.defaults.requires_diff' "$REGISTRY")"
    [[ "$REQUIRES_DIFF" == "null" ]] && REQUIRES_DIFF="true"
  fi

  # Skip diff-dependent skills when no --base provided
  if [[ "$REQUIRES_DIFF" != "false" ]] && [[ -z "$BASE_REF" ]]; then
    SKIPPED=$((SKIPPED + 1))
    echo "  ⊘ $skill_name [skipped: requires --base for diff context]"
    RESULT_ENTRY="$(jq -n \
      --arg name "$skill_name" \
      --arg status "skipped" \
      --arg reason "requires_diff without --base" \
      --arg mandatory "$IS_MANDATORY" \
      '{name: $name, status: $status, skipped_reason: $reason, blocking: 0, major: 0, warning: 0, exit_code: 0, mandatory: ($mandatory == "true")}')"
    SKILL_RESULTS_JSON="$(echo "$SKILL_RESULTS_JSON" | jq --argjson entry "$RESULT_ENTRY" '. + [$entry]')"
    continue
  fi

  # Predicate filtering (mode-based routing + --diff-profile only)
  if [[ -n "$DIFF_PROFILE" ]] && [[ -n "$MODE" ]]; then
    if ! evaluate_predicates "$skill_name" "$DIFF_PROFILE"; then
      SKIPPED=$((SKIPPED + 1))
      echo "  ⊘ $skill_name [skipped: no predicate match]"
      RESULT_ENTRY="$(jq -n \
        --arg name "$skill_name" \
        --arg status "skipped" \
        --arg reason "no predicate match" \
        --arg mandatory "$IS_MANDATORY" \
        '{name: $name, status: $status, skipped_reason: $reason, blocking: 0, major: 0, warning: 0, exit_code: 0, mandatory: ($mandatory == "true")}')"
      SKILL_RESULTS_JSON="$(echo "$SKILL_RESULTS_JSON" | jq --argjson entry "$RESULT_ENTRY" '. + [$entry]')"
      continue
    fi
  fi

  echo "▶ Running: $skill_name [$SKILL_COST]"

  EXTRA_ARGS=""
  if [[ -n "$SCOPE" ]]; then
    EXTRA_ARGS+=" --scope $SCOPE"
  fi
  if [[ -n "$BASE_REF" ]]; then
    EXTRA_ARGS+=" --base $BASE_REF"
  fi

  SKILL_OUTPUT=""
  SKILL_EXIT=0
  # shellcheck disable=SC2086
  SKILL_OUTPUT="$("$AI_SKILL" "$skill_name" $EXTRA_ARGS 2>&1)" || SKILL_EXIT=$?

  # Save individual output
  echo "$SKILL_OUTPUT" > "$OUT_DIR/$skill_name.json"

  # Extract status and blocking count from JSON output
  SKILL_STATUS="$(echo "$SKILL_OUTPUT" | jq -r '.status // "unknown"' 2>/dev/null || echo "error")"
  SKILL_BLOCKING="$(echo "$SKILL_OUTPUT" | jq '.blocking // [] | length' 2>/dev/null || echo "0")"
  SKILL_MAJOR="$(echo "$SKILL_OUTPUT" | jq '.major // [] | length' 2>/dev/null || echo "0")"
  SKILL_WARNING="$(echo "$SKILL_OUTPUT" | jq '.warning // [] | length' 2>/dev/null || echo "0")"

  # Build result entry
  RESULT_ENTRY="$(jq -n \
    --arg name "$skill_name" \
    --arg status "$SKILL_STATUS" \
    --argjson blocking "$SKILL_BLOCKING" \
    --argjson major "$SKILL_MAJOR" \
    --argjson warning "$SKILL_WARNING" \
    --argjson exit_code "$SKILL_EXIT" \
    --arg mandatory "$IS_MANDATORY" \
    '{name: $name, status: $status, blocking: $blocking, major: $major, warning: $warning, exit_code: $exit_code, mandatory: ($mandatory == "true")}')"
  SKILL_RESULTS_JSON="$(echo "$SKILL_RESULTS_JSON" | jq --argjson entry "$RESULT_ENTRY" '. + [$entry]')"

  if [[ "$SKILL_EXIT" -eq 0 ]]; then
    PASSED=$((PASSED + 1))
    echo "  ✔ $skill_name (blocking:$SKILL_BLOCKING major:$SKILL_MAJOR warning:$SKILL_WARNING)"
  else
    FAILED=$((FAILED + 1))
    if [[ "$IS_MANDATORY" == "true" ]]; then
      echo "  ✖ $skill_name [mandatory] (blocking:$SKILL_BLOCKING major:$SKILL_MAJOR warning:$SKILL_WARNING)"
      BLOCKING_FAILED=$((BLOCKING_FAILED + 1))
      if [[ "$FAIL_FAST" == "true" ]]; then
        echo "✖ Mandatory failure (--fail-fast): $skill_name" >&2
        break
      fi
    else
      echo "  ⚠ $skill_name [non-mandatory] (blocking:$SKILL_BLOCKING major:$SKILL_MAJOR warning:$SKILL_WARNING)"
    fi
  fi
done <<< "$ORDERED_SKILLS"

# --- Write aggregate JSON output -----------------------------------------

SUMMARY_JSON="$(jq -n \
  --arg source "$SOURCE" \
  --arg timestamp "$TIMESTAMP" \
  --argjson total "$TOTAL" \
  --argjson passed "$PASSED" \
  --argjson failed "$FAILED" \
  --argjson skipped "$SKIPPED" \
  --argjson blocking_failed "$BLOCKING_FAILED" \
  --argjson results "$SKILL_RESULTS_JSON" \
  '{source: $source, timestamp: $timestamp, total: $total, passed: $passed, failed: $failed, skipped: $skipped, blocking_failed: $blocking_failed, results: $results}')"

echo "$SUMMARY_JSON" > "$OUT_DIR/ai-check.json"

# Also write to stable path for other tools
echo "$SUMMARY_JSON" > "$AI_DIR/out/ai-check.json"

# --- Summary --------------------------------------------------------------

echo
echo "═══ ai-check summary ═══"
echo "Source: $SOURCE"
echo "Results: $PASSED/$TOTAL passed ($FAILED failed, $SKIPPED skipped, $BLOCKING_FAILED blocking)"
echo "Output: $OUT_DIR/"

# Fail if all skills were skipped — but distinguish skip reasons.
# requires_diff skips (no --base) are false passes → exit 1.
# Predicate-filtered skips are legitimate narrowing → pass with note.
if [[ "$TOTAL" -gt 0 ]] && [[ "$SKIPPED" -eq "$TOTAL" ]]; then
  DIFF_SKIPS="$(echo "$SKILL_RESULTS_JSON" | jq '[.[] | select(.skipped_reason == "requires_diff without --base")] | length')"
  PREDICATE_SKIPS="$(echo "$SKILL_RESULTS_JSON" | jq '[.[] | select(.skipped_reason == "no predicate match")] | length')"
  if [[ "$DIFF_SKIPS" -gt 0 ]] && [[ "$PREDICATE_SKIPS" -eq 0 ]]; then
    # All skipped due to missing --base — no validation occurred
    echo
    echo "✖ All $TOTAL skill(s) were skipped — no validation occurred" >&2
    echo "  hint: pass --base <ref> to provide diff context for requires_diff skills" >&2
    exit 1
  elif [[ "$PREDICATE_SKIPS" -gt 0 ]]; then
    # All skipped by predicates — legitimate narrow diff, pass with note
    echo
    echo "ℹ All $TOTAL skill(s) skipped by predicate filtering (narrow diff)"
  else
    # Mixed or unknown skip reasons — fail safe
    echo
    echo "✖ All $TOTAL skill(s) were skipped — no validation occurred" >&2
    exit 1
  fi
fi

if [[ "$BLOCKING_FAILED" -gt 0 ]]; then
  echo
  echo "✖ $BLOCKING_FAILED skill(s) had blocking findings" >&2
  exit 1
fi

exit 0
