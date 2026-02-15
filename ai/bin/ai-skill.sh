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

command -v claude >/dev/null 2>&1 || {
  echo "error: claude not found. Run ./ai/deps.sh" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || {
  echo "error: jq not found" >&2
  exit 1
}

command -v yq >/dev/null 2>&1 || {
  echo "error: yq not found" >&2
  exit 1
}

# --- Parse arguments ------------------------------------------------------

SKILL_NAME=""
SKILL_VERSION=""
SCOPE=""
BASE_REF=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      [[ $# -ge 2 ]] || { echo "error: --version requires a value" >&2; exit 1; }
      SKILL_VERSION="$2"; shift 2 ;;
    --scope)
      [[ $# -ge 2 ]] || { echo "error: --scope requires a value" >&2; exit 1; }
      SCOPE="$2"; shift 2 ;;
    --base)
      [[ $# -ge 2 ]] || { echo "error: --base requires a value" >&2; exit 1; }
      BASE_REF="$2"; shift 2 ;;
    -*)
      echo "error: unknown flag: $1" >&2; exit 1 ;;
    *)
      [[ -z "$SKILL_NAME" ]] || { echo "error: unexpected argument: $1" >&2; exit 1; }
      SKILL_NAME="$1"; shift ;;
  esac
done

if [[ -z "$SKILL_NAME" ]]; then
  echo "usage: ai-skill.sh <skill-name> [--version vX] [--scope path1,path2] [--base <ref>]" >&2
  exit 1
fi

# --- Resolve skill from registry ------------------------------------------

REGISTRY="$AI_DIR/skills.yaml"
if [[ ! -f "$REGISTRY" ]]; then
  echo "error: registry not found: $REGISTRY" >&2
  exit 1
fi

# Query registry with yq
SKILL_QUERY=".registry[] | select(.name == \"$SKILL_NAME\")"

REG_VERSION="$(yq e "$SKILL_QUERY | .version" "$REGISTRY")"
REG_PATH="$(yq e "$SKILL_QUERY | .path" "$REGISTRY")"
IN_REGISTRY=true

if [[ -z "$REG_VERSION" ]] || [[ "$REG_VERSION" == "null" ]]; then
  IN_REGISTRY=false
fi

# Use --version override if provided, otherwise registry default
if [[ -n "$SKILL_VERSION" ]]; then
  RESOLVED_VERSION="$SKILL_VERSION"
elif [[ "$IN_REGISTRY" == "true" ]]; then
  RESOLVED_VERSION="$REG_VERSION"
else
  echo "error: skill '$SKILL_NAME' not in global registry; --version required" >&2
  exit 1
fi

# Resolve skill directory with repo-local precedence.
# Repo-local: repo-root/ai/skills/<skill>/<version>/
# Global:     dotfiles/ai/skills/<skill>/<version>/ (via registry path)

REPO_ROOT="$PWD"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
fi

REPO_LOCAL_SKILL="$REPO_ROOT/ai/skills/$SKILL_NAME/$RESOLVED_VERSION"

GLOBAL_SKILL=""
if [[ "$IN_REGISTRY" == "true" ]]; then
  if [[ -n "$SKILL_VERSION" ]]; then
    GLOBAL_SKILL="$AI_DIR/${REG_PATH%/*}/$RESOLVED_VERSION"
  else
    GLOBAL_SKILL="$AI_DIR/$REG_PATH"
  fi
fi

# Mandatory flag means "must be invoked" (enforced in Part VIII trigger strategy),
# NOT "cannot have repo-local version." Repo-local versions specialize the check
# for the target repo. Global constitutional rules are protected by injection order
# (global CLAUDE.md is always loaded first and cannot be weakened).

if [[ -d "$REPO_LOCAL_SKILL" ]]; then
  SKILL_DIR="$REPO_LOCAL_SKILL"
  SKILL_SOURCE="repo-local"
elif [[ -n "$GLOBAL_SKILL" ]] && [[ -d "$GLOBAL_SKILL" ]]; then
  SKILL_DIR="$GLOBAL_SKILL"
  SKILL_SOURCE="global"
else
  echo "error: skill directory not found (checked repo-local and global)" >&2
  echo "  repo-local: $REPO_LOCAL_SKILL" >&2
  [[ -n "$GLOBAL_SKILL" ]] && echo "  global:     $GLOBAL_SKILL" >&2
  exit 1
fi

# --- Validate required files ----------------------------------------------
# SKILL.md: native Agent Skills format (frontmatter + instructions)
# input.schema.json: contract document (scaffold completeness, not runtime-validated)
# output.schema.json: enforced at API level and defense-in-depth

for f in SKILL.md input.schema.json output.schema.json; do
  if [[ ! -f "$SKILL_DIR/$f" ]]; then
    echo "error: missing required file: $SKILL_DIR/$f" >&2
    exit 1
  fi
done

# --- Build repo tree ------------------------------------------------------

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Include both tracked and untracked files (skills need to see new files)
  REPO_TREE="$({ git ls-files; git ls-files --others --exclude-standard; } | LC_ALL=C sort -u)"
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

if [[ -z "$REPO_TREE" ]]; then
  echo "error: scope produced empty repo tree" >&2
  exit 1
fi

# --- Load files -----------------------------------------------------------

CLAUDE_MD=""
if [[ -f "$AI_DIR/CLAUDE.md" ]]; then
  CLAUDE_MD="$(cat "$AI_DIR/CLAUDE.md")"
fi

# Read SKILL.md body (strip YAML frontmatter)
SKILL_BODY="$(sed '1{/^---$/!q}; 1,/^---$/d' "$SKILL_DIR/SKILL.md")"
OUTPUT_SCHEMA="$(cat "$SKILL_DIR/output.schema.json")"

# Optional repo-local CLAUDE.md (repo constitution, additive to global)
REPO_CLAUDE_MD=""
if [[ -f "$REPO_ROOT/CLAUDE.md" ]]; then
  REPO_CLAUDE_MD="$(cat "$REPO_ROOT/CLAUDE.md")"
fi

# Optional repo-local AGENTS.md
AGENTS_MD=""
if [[ -f "$REPO_ROOT/AGENTS.md" ]]; then
  AGENTS_MD="$(cat "$REPO_ROOT/AGENTS.md")"
fi

# Optional ARCH_INDEX.md (structural ontology — skills need contents, not just path)
# Check both root and docs/ locations
ARCH_INDEX=""
for _arch_path in "$REPO_ROOT/ARCH_INDEX.md" "$REPO_ROOT/docs/ARCH_INDEX.md"; do
  if [[ -f "$_arch_path" ]]; then
    ARCH_INDEX="$(cat "$_arch_path")"
    break
  fi
done

# --- Build prompts --------------------------------------------------------
# Injection order: Global CLAUDE.md → Repo CLAUDE.md → AGENTS.md → ARCH_INDEX → SKILL.md

SYSTEM_PROMPT="You are operating in VALIDATOR mode.

${CLAUDE_MD}"

if [[ -n "$REPO_CLAUDE_MD" ]]; then
  SYSTEM_PROMPT="${SYSTEM_PROMPT}

Repo-local constitution (CLAUDE.md):

${REPO_CLAUDE_MD}"
fi

if [[ -n "$AGENTS_MD" ]]; then
  SYSTEM_PROMPT="${SYSTEM_PROMPT}

Repo-local constraints (AGENTS.md):

${AGENTS_MD}"
fi

if [[ -n "$ARCH_INDEX" ]]; then
  SYSTEM_PROMPT="${SYSTEM_PROMPT}

Architecture index (docs/ARCH_INDEX.md):

${ARCH_INDEX}"
fi

SYSTEM_PROMPT="${SYSTEM_PROMPT}

${SKILL_BODY}

You must output valid JSON conforming exactly to this schema:

${OUTPUT_SCHEMA}

No markdown. No prose. No explanation. No code fences. JSON only."

# --- Build diff payload (if --base provided) --------------------------------

DIFF_PAYLOAD=""
if [[ -n "$BASE_REF" ]] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Diff merge-base to working tree (includes uncommitted session edits)
  DIFF_PAYLOAD="$(git diff "$BASE_REF" 2>/dev/null || true)"

  # Append synthetic diff for untracked files (git diff never includes these)
  UNTRACKED="$(git ls-files --others --exclude-standard 2>/dev/null || true)"
  if [[ -n "$UNTRACKED" ]]; then
    UNTRACKED_DIFF=""
    while IFS= read -r ufile; do
      [[ -n "$ufile" ]] || continue
      [[ -f "$ufile" ]] || continue
      # Build unified diff header for new file
      UNTRACKED_DIFF="${UNTRACKED_DIFF}
diff --git a/$ufile b/$ufile
new file mode 100644
--- /dev/null
+++ b/$ufile
$(git diff --no-index /dev/null "$ufile" 2>/dev/null | tail -n +5 || true)"
    done <<< "$UNTRACKED"
    if [[ -n "$UNTRACKED_DIFF" ]]; then
      DIFF_PAYLOAD="${DIFF_PAYLOAD}${UNTRACKED_DIFF}"
    fi
  fi
fi

USER_PROMPT="Evaluate the following repository.

Repository tree:
${REPO_TREE}"

if [[ -n "$DIFF_PAYLOAD" ]]; then
  USER_PROMPT="${USER_PROMPT}

Diff (base: ${BASE_REF}):
${DIFF_PAYLOAD}"
fi

USER_PROMPT="${USER_PROMPT}

Respond with JSON only. No other text."

# --- Invoke Claude (non-interactive, no tools, ephemeral) -----------------

RESPONSE="$(echo "$USER_PROMPT" | CLAUDECODE= claude -p \
  --system-prompt "$SYSTEM_PROMPT" \
  --tools "" \
  --disable-slash-commands \
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

# Defense-in-depth: validate unified output schema.
# All skills must return: skill, version, status, blocking, major, warning, info
SCHEMA_ERRORS=""

# Check required string fields
for key in skill version status; do
  KEY_TYPE="$(echo "$RESPONSE" | jq -r ".[\"$key\"] | type")"
  if [[ "$KEY_TYPE" == "null" ]]; then
    SCHEMA_ERRORS+="missing required key: $key\n"
  elif [[ "$KEY_TYPE" != "string" ]]; then
    SCHEMA_ERRORS+="$key: expected string, got $KEY_TYPE\n"
  fi
done

# Check status enum
STATUS="$(echo "$RESPONSE" | jq -r '.status // ""')"
if [[ -n "$STATUS" ]] && [[ "$STATUS" != "pass" ]] && [[ "$STATUS" != "fail" ]]; then
  SCHEMA_ERRORS+="status: must be \"pass\" or \"fail\", got \"$STATUS\"\n"
fi

# Check required array fields (must be arrays of strings)
for key in blocking major warning info; do
  KEY_TYPE="$(echo "$RESPONSE" | jq -r ".[\"$key\"] | type")"
  if [[ "$KEY_TYPE" == "null" ]]; then
    SCHEMA_ERRORS+="missing required key: $key\n"
  elif [[ "$KEY_TYPE" != "array" ]]; then
    SCHEMA_ERRORS+="$key: expected array, got $KEY_TYPE\n"
  else
    NON_STRING="$(echo "$RESPONSE" | jq "[.[\"$key\"][] | select(type != \"string\")] | length")"
    if [[ "$NON_STRING" -gt 0 ]]; then
      SCHEMA_ERRORS+="$key: all elements must be strings ($NON_STRING non-string element(s) found)\n"
    fi
  fi
done

if [[ -n "$SCHEMA_ERRORS" ]]; then
  echo "error: response does not conform to unified output schema:" >&2
  printf "  %b" "$SCHEMA_ERRORS" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

# --- Output ---------------------------------------------------------------

echo "$RESPONSE" | jq .

# --- Exit code: fail if status=fail AND blocking is non-empty -------------

BLOCKING_COUNT="$(echo "$RESPONSE" | jq '.blocking | length')"
if [[ "$STATUS" == "fail" ]] && [[ "$BLOCKING_COUNT" -gt 0 ]]; then
  exit 1
fi
