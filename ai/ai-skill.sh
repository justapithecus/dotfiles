#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Preflight ------------------------------------------------------------

command -v claude >/dev/null 2>&1 || {
  echo "error: claude not found. Run ./ai/deps.sh" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || {
  echo "error: jq not found" >&2
  exit 1
}

# --- Parse arguments ------------------------------------------------------

SKILL_NAME=""
SKILL_VERSION=""
SCOPE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      [[ $# -ge 2 ]] || { echo "error: --version requires a value" >&2; exit 1; }
      SKILL_VERSION="$2"; shift 2 ;;
    --scope)
      [[ $# -ge 2 ]] || { echo "error: --scope requires a value" >&2; exit 1; }
      SCOPE="$2"; shift 2 ;;
    -*)
      echo "error: unknown flag: $1" >&2; exit 1 ;;
    *)
      [[ -z "$SKILL_NAME" ]] || { echo "error: unexpected argument: $1" >&2; exit 1; }
      SKILL_NAME="$1"; shift ;;
  esac
done

if [[ -z "$SKILL_NAME" ]]; then
  echo "usage: ai-skill.sh <skill-name> [--version vX] [--scope path1,path2]" >&2
  exit 1
fi

# --- Resolve skill from registry ------------------------------------------

REGISTRY="$SCRIPT_DIR/skills.yaml"
if [[ ! -f "$REGISTRY" ]]; then
  echo "error: registry not found: $REGISTRY" >&2
  exit 1
fi

# Extract skill block (lines between matching "- name:" and next "- name:")
SKILL_BLOCK="$(awk -v skill="$SKILL_NAME" '
  /^[[:space:]]*- name:[[:space:]]/ {
    gsub(/^[[:space:]]*- name:[[:space:]]*/, "")
    gsub(/[[:space:]]*$/, "")
    if ($0 == skill) { found=1 } else { found=0 }
    next
  }
  found { print }
' "$REGISTRY")"

if [[ -z "$SKILL_BLOCK" ]]; then
  echo "error: skill not found in registry: $SKILL_NAME" >&2
  exit 1
fi

REG_VERSION="$(echo "$SKILL_BLOCK" | awk '/^[[:space:]]*version:/ {
  gsub(/^[[:space:]]*version:[[:space:]]*/, "")
  gsub(/[[:space:]]*$/, "")
  print; exit
}')"

REG_PATH="$(echo "$SKILL_BLOCK" | awk '/^[[:space:]]*path:/ {
  gsub(/^[[:space:]]*path:[[:space:]]*/, "")
  gsub(/[[:space:]]*$/, "")
  print; exit
}')"

# Use --version override if provided, otherwise registry default
RESOLVED_VERSION="${SKILL_VERSION:-$REG_VERSION}"

if [[ -z "$RESOLVED_VERSION" ]]; then
  echo "error: no version found for skill: $SKILL_NAME" >&2
  exit 1
fi

# Resolve skill directory (paths are relative to registry file's directory)
if [[ -n "$SKILL_VERSION" ]]; then
  # Derive path from registry path, replacing version segment
  SKILL_DIR="$SCRIPT_DIR/${REG_PATH%/*}/$RESOLVED_VERSION"
else
  SKILL_DIR="$SCRIPT_DIR/$REG_PATH"
fi

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "error: skill directory not found: $SKILL_DIR" >&2
  exit 1
fi

# --- Validate required files ----------------------------------------------

for f in metadata.yaml system.md input.schema.json output.schema.json; do
  if [[ ! -f "$SKILL_DIR/$f" ]]; then
    echo "error: missing required file: $SKILL_DIR/$f" >&2
    exit 1
  fi
done

# --- Detect repo root -----------------------------------------------------

REPO_ROOT="$PWD"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi

# --- Build repo tree ------------------------------------------------------

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_TREE="$(git ls-files)"
else
  REPO_TREE="$(cd "$REPO_ROOT" && find . -type f | sed 's|^\./||' | LC_ALL=C sort)"
fi

# Apply scope filter
if [[ -n "$SCOPE" ]]; then
  FILTERED=""
  IFS=',' read -ra SCOPE_PARTS <<< "$SCOPE"
  for prefix in "${SCOPE_PARTS[@]}"; do
    prefix="$(echo "$prefix" | sed 's/[[:space:]]//g')"
    MATCHES="$(echo "$REPO_TREE" | awk -v p="$prefix" 'substr($0, 1, length(p)) == p')"
    if [[ -n "$MATCHES" ]]; then
      FILTERED="${FILTERED:+${FILTERED}
}${MATCHES}"
    fi
  done
  REPO_TREE="$FILTERED"
fi

# --- Load files -----------------------------------------------------------

CLAUDE_MD=""
if [[ -f "$SCRIPT_DIR/CLAUDE.md" ]]; then
  CLAUDE_MD="$(cat "$SCRIPT_DIR/CLAUDE.md")"
fi

SYSTEM_MD="$(cat "$SKILL_DIR/system.md")"
OUTPUT_SCHEMA="$(cat "$SKILL_DIR/output.schema.json")"

# Optional repo-local AGENTS.md
AGENTS_MD=""
if [[ -f "$REPO_ROOT/AGENTS.md" ]]; then
  AGENTS_MD="$(cat "$REPO_ROOT/AGENTS.md")"
fi

# --- Build prompts --------------------------------------------------------

SYSTEM_PROMPT="You are operating in VALIDATOR mode.

${CLAUDE_MD}

${SYSTEM_MD}

You must output valid JSON conforming exactly to this schema:

${OUTPUT_SCHEMA}

No markdown. No prose. No explanation. No code fences. JSON only."

USER_PROMPT="Evaluate the following repository.

Repository tree:
${REPO_TREE}

Constitution (CLAUDE.md):
${CLAUDE_MD}"

if [[ -n "$AGENTS_MD" ]]; then
  USER_PROMPT="${USER_PROMPT}

AGENTS.md:
${AGENTS_MD}"
fi

USER_PROMPT="${USER_PROMPT}

Respond with JSON only. No other text."

# --- Invoke Claude (non-interactive, no tools, ephemeral) -----------------

RESPONSE="$(echo "$USER_PROMPT" | CLAUDECODE= claude -p \
  --system-prompt "$SYSTEM_PROMPT" \
  --tools "" \
  --no-session-persistence \
  --output-format text \
  2>/dev/null)" || {
  echo "error: claude invocation failed" >&2
  exit 1
}

# --- Validate response ----------------------------------------------------

if [[ -z "$RESPONSE" ]]; then
  echo "error: claude returned empty response" >&2
  exit 1
fi

# Strip markdown code fences if present
RESPONSE="$(echo "$RESPONSE" | sed '/^```\(json\)\{0,1\}$/d')"

if ! echo "$RESPONSE" | jq . >/dev/null 2>&1; then
  echo "error: claude returned invalid JSON" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

# Validate response against output.schema.json contract:
#   - All required keys present
#   - No additional properties
#   - Each value is an array of strings
SCHEMA_ERRORS="$(echo "$RESPONSE" | jq -r '
  def check:
    (keys - ["violations","redundancies","forbidden_exists","ambiguities"]) as $extra |
    (["violations","redundancies","forbidden_exists","ambiguities"] - keys) as $missing |
    [
      ($missing[] | "missing required key: \(.)"),
      ($extra[] | "unexpected key: \(.)"),
      (to_entries[] |
        select(.key == "violations" or .key == "redundancies"
            or .key == "forbidden_exists" or .key == "ambiguities") |
        if (.value | type) != "array" then
          "\(.key): expected array, got \(.value | type)"
        else
          (.value | to_entries[] |
            if (.value | type) != "string" then
              "\(.key)[\(.key)]: expected string, got \(.value | type)"
            else empty end)
        end)
    ] | .[];
  check
')"

if [[ -n "$SCHEMA_ERRORS" ]]; then
  echo "error: response does not conform to output schema:" >&2
  echo "$SCHEMA_ERRORS" | sed 's/^/  /' >&2
  echo "$RESPONSE" >&2
  exit 1
fi

# --- Output ---------------------------------------------------------------

echo "$RESPONSE" | jq .

# Exit non-zero if violations or forbidden_exists present
VIOLATIONS="$(echo "$RESPONSE" | jq '.violations | length')"
FORBIDDEN="$(echo "$RESPONSE" | jq '.forbidden_exists | length')"

if [[ "$VIOLATIONS" -gt 0 ]] || [[ "$FORBIDDEN" -gt 0 ]]; then
  exit 1
fi
