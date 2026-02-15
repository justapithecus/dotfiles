#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
AI_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Preflight ------------------------------------------------------------

command -v yq >/dev/null 2>&1 || {
  echo "error: yq not found" >&2
  exit 1
}

REGISTRY="$AI_DIR/skills.yaml"
ROLES_DIR="$AI_DIR/roles"

# --- Skills ---------------------------------------------------------------

echo "═══ Skills ═══"
if [[ -f "$REGISTRY" ]]; then
  yq e '.registry[] | "  " + .name + " (" + .version + ") [" + .cost + "]" + (select(.mandatory == true) | " *mandatory*" // "")' "$REGISTRY" 2>/dev/null || true
  # Fallback: simpler listing if yq expression fails
  if [[ $? -ne 0 ]]; then
    yq e '.registry[].name' "$REGISTRY" | sed 's/^/  /'
  fi
else
  echo "  (no registry found)"
fi

echo

# --- Bundles --------------------------------------------------------------

echo "═══ Bundles ═══"
if [[ -f "$REGISTRY" ]]; then
  for bundle in $(yq e '.bundles | keys | .[]' "$REGISTRY" 2>/dev/null); do
    echo "  $bundle:"
    yq e ".bundles.$bundle[]" "$REGISTRY" | sed 's/^/    - /'
  done
else
  echo "  (no registry found)"
fi

echo

# --- Roles ----------------------------------------------------------------

echo "═══ Roles ═══"
if [[ -d "$ROLES_DIR" ]]; then
  for role_file in "$ROLES_DIR"/*.md; do
    [[ -f "$role_file" ]] || continue
    echo "  $(basename "${role_file%.md}")"
  done
else
  echo "  (no roles directory found)"
fi
