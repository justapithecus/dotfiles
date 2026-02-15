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
SCOPE=""
FAIL_FAST=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle)
      [[ $# -ge 2 ]] || { echo "error: --bundle requires a value" >&2; exit 1; }
      BUNDLE="$2"; shift 2 ;;
    --scope)
      [[ $# -ge 2 ]] || { echo "error: --scope requires a value" >&2; exit 1; }
      SCOPE="$2"; shift 2 ;;
    --fail-fast)
      FAIL_FAST=true; shift ;;
    -h|--help)
      echo "usage: ai-check [--bundle <name>] [--scope path,...] [--fail-fast]"
      echo
      echo "Bundles:"
      yq e '.bundles | keys | .[]' "$AI_DIR/skills.yaml" 2>/dev/null | sed 's/^/  /'
      exit 0 ;;
    *)
      echo "error: unknown argument: $1" >&2; exit 1 ;;
  esac
done

# --- Resolve bundle -------------------------------------------------------

REGISTRY="$AI_DIR/skills.yaml"
if [[ ! -f "$REGISTRY" ]]; then
  echo "error: registry not found: $REGISTRY" >&2
  exit 1
fi

BUNDLE_SKILLS="$(yq e ".bundles.$BUNDLE[]" "$REGISTRY" 2>/dev/null)"
if [[ -z "$BUNDLE_SKILLS" ]] || [[ "$BUNDLE_SKILLS" == "null" ]]; then
  echo "error: bundle '$BUNDLE' not found in registry" >&2
  echo "Available bundles:" >&2
  yq e '.bundles | keys | .[]' "$REGISTRY" | sed 's/^/  /' >&2
  exit 1
fi

# --- Sort skills by cost then mode ----------------------------------------
# cost_order: cheap=0, moderate=1, heavy=2
# mode_order: deterministic=0, heuristic=1, semantic=2

SORTED_SKILLS=""
while IFS= read -r skill_name; do
  [[ -n "$skill_name" ]] || continue
  COST="$(yq e ".registry[] | select(.name == \"$skill_name\") | .cost" "$REGISTRY" 2>/dev/null)"
  MODE="$(yq e ".registry[] | select(.name == \"$skill_name\") | .mode" "$REGISTRY" 2>/dev/null)"
  case "$COST" in
    cheap)    COST_N=0 ;;
    moderate) COST_N=1 ;;
    heavy)    COST_N=2 ;;
    *)        COST_N=9 ;;
  esac
  case "$MODE" in
    deterministic) MODE_N=0 ;;
    heuristic)     MODE_N=1 ;;
    semantic)      MODE_N=2 ;;
    *)             MODE_N=9 ;;
  esac
  SORTED_SKILLS+="${COST_N}${MODE_N} ${skill_name}\n"
done <<< "$BUNDLE_SKILLS"

ORDERED_SKILLS="$(printf "%b" "$SORTED_SKILLS" | LC_ALL=C sort | awk '{print $2}')"

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
BLOCKING_FAILED=0
SKILL_RESULTS_JSON="[]"

while IFS= read -r skill_name; do
  [[ -n "$skill_name" ]] || continue
  TOTAL=$((TOTAL + 1))

  # Check mandatory flag from registry
  IS_MANDATORY="$(yq e ".registry[] | select(.name == \"$skill_name\") | .mandatory" "$REGISTRY")"
  SKILL_COST="$(yq e ".registry[] | select(.name == \"$skill_name\") | .cost" "$REGISTRY")"

  echo "▶ Running: $skill_name [$SKILL_COST]"

  SCOPE_ARG=""
  if [[ -n "$SCOPE" ]]; then
    SCOPE_ARG="--scope $SCOPE"
  fi

  SKILL_OUTPUT=""
  SKILL_EXIT=0
  # shellcheck disable=SC2086
  SKILL_OUTPUT="$("$AI_SKILL" "$skill_name" $SCOPE_ARG 2>&1)" || SKILL_EXIT=$?

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
  --arg bundle "$BUNDLE" \
  --arg timestamp "$TIMESTAMP" \
  --argjson total "$TOTAL" \
  --argjson passed "$PASSED" \
  --argjson failed "$FAILED" \
  --argjson blocking_failed "$BLOCKING_FAILED" \
  --argjson results "$SKILL_RESULTS_JSON" \
  '{bundle: $bundle, timestamp: $timestamp, total: $total, passed: $passed, failed: $failed, blocking_failed: $blocking_failed, results: $results}')"

echo "$SUMMARY_JSON" > "$OUT_DIR/ai-check.json"

# Also write to stable path for other tools
echo "$SUMMARY_JSON" > "$AI_DIR/out/ai-check.json"

# --- Summary --------------------------------------------------------------

echo
echo "═══ ai-check summary ═══"
echo "Bundle: $BUNDLE"
echo "Results: $PASSED/$TOTAL passed ($BLOCKING_FAILED blocking)"
echo "Output: $OUT_DIR/"

if [[ "$BLOCKING_FAILED" -gt 0 ]]; then
  echo
  echo "✖ $BLOCKING_FAILED skill(s) had blocking findings" >&2
  exit 1
fi

exit 0
