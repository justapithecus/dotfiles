#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
AI_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Preflight ------------------------------------------------------------

command -v yq >/dev/null 2>&1 || {
  echo "error: yq not found" >&2
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

# --- Create output directory ----------------------------------------------

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$AI_DIR/out/$TIMESTAMP"
mkdir -p "$OUT_DIR"

# --- Run skills -----------------------------------------------------------

TOTAL=0
PASSED=0
FAILED=0
MANDATORY_FAILED=0
RESULTS=()

while IFS= read -r skill_name; do
  [[ -n "$skill_name" ]] || continue
  TOTAL=$((TOTAL + 1))

  # Check mandatory flag from registry
  IS_MANDATORY="$(yq e ".registry[] | select(.name == \"$skill_name\") | .mandatory" "$REGISTRY")"

  echo "▶ Running: $skill_name"

  SCOPE_ARG=""
  if [[ -n "$SCOPE" ]]; then
    SCOPE_ARG="--scope $SCOPE"
  fi

  SKILL_OUTPUT=""
  SKILL_EXIT=0
  # shellcheck disable=SC2086
  AI_SKILL="${SCRIPT_DIR}/ai-skill.sh"
  command -v ai-skill >/dev/null 2>&1 && AI_SKILL="ai-skill"
  SKILL_OUTPUT="$("$AI_SKILL" "$skill_name" $SCOPE_ARG 2>&1)" || SKILL_EXIT=$?

  # Save output
  echo "$SKILL_OUTPUT" > "$OUT_DIR/$skill_name.json"

  if [[ "$SKILL_EXIT" -eq 0 ]]; then
    PASSED=$((PASSED + 1))
    RESULTS+=("  ✔ $skill_name")
  else
    FAILED=$((FAILED + 1))
    RESULTS+=("  ✖ $skill_name")
    if [[ "$IS_MANDATORY" == "true" ]]; then
      MANDATORY_FAILED=$((MANDATORY_FAILED + 1))
      if [[ "$FAIL_FAST" == "true" ]]; then
        echo "✖ Mandatory skill failed (--fail-fast): $skill_name" >&2
        echo "$SKILL_OUTPUT" >&2
        exit 1
      fi
    fi
  fi
done <<< "$BUNDLE_SKILLS"

# --- Summary --------------------------------------------------------------

echo
echo "═══ ai-check summary ═══"
echo "Bundle: $BUNDLE"
echo "Results: $PASSED/$TOTAL passed"
for line in "${RESULTS[@]}"; do
  echo "$line"
done
echo "Output: $OUT_DIR/"

if [[ "$MANDATORY_FAILED" -gt 0 ]]; then
  echo
  echo "✖ $MANDATORY_FAILED mandatory skill(s) failed" >&2
  exit 1
fi

exit 0
