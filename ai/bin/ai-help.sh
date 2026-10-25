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

COMMANDS="chat plan implement review patch skill check list help install-hooks migrate"

# ==========================================================================
# ai-help (no args) — command overview
# ==========================================================================

show_overview() {
  cat <<'EOF'
AI Governance Toolkit

Commands:
  ai-chat [role]                    Interactive session (default: architect)
  ai-plan                           Planning session (may produce plan.json)
  ai-implement                      Implementation with auto-gating (alias: aii)
  ai-review                         Codex code review
  ai-patch "task"                   Three-phase patch surgery
  ai-skill <name> [opts]            Run a single governance skill
  ai-check [--mode|--bundle] [opts] Governance orchestrator
  ai-list                           List skills, bundles, and roles
  ai-help [command|workflows]       This help
  ai-install-hooks                  Install pre-push git hook
  ai-migrate [/path/to/repo]        Migrate repo (Phases A-E)

Guides:
  ai/docs/quickstart.md             First-time setup
  ai/docs/workflows.md              Common patterns and troubleshooting

Run 'ai-help <command>' for detailed usage.
Run 'ai-help workflows' for workflow recipes.
EOF
}

# ==========================================================================
# ai-help workflows — inline workflow recipes
# ==========================================================================

show_workflows() {
  cat <<'EOF'
Workflow Recipes

1. Plan-then-implement (standard loop)

   git worktree add -b feature/my-change ../repo-my-change main
   cd ../repo-my-change
   ai-plan                          # read-only; optionally writes plan.json
   ai-implement                     # consumes plan.json, auto-gates on exit

2. Quick patch

   ai-patch "fix the typo in README.md"
   # Phase 1: Claude plans scoped changes (patch-architect)
   # Phase 2: Codex emits minimal diffs (patcher)
   # Phase 3: ai-check validates with patch bundle

3. Manual governance check

   ai-check --mode NORMAL           # auto-routed (15 skills)
   ai-check --mode PATCH            # surgical edits (7 skills)
   ai-check --mode STRUCTURAL       # structural changes (17 skills)
   ai-check --bundle default        # bundle routing (listing order)
   ai-check --mode HEAVY --base main --fail-fast

4. Single skill validation

   ai-skill repo-convention-enforcer
   ai-skill scope-violation-detector --base main --scope ai/

5. Troubleshooting

   Problem: "claude not found"
   Fix:     Run ./ai/deps.sh to install claude and codex

   Problem: "yq not found"
   Fix:     Run ./ai/deps.sh or install yq manually

   Problem: "cannot locate ai/ directory"
   Fix:     Set AI_DIR or run ./ai/install.sh to reinstall

   Problem: "All skills were skipped"
   Fix:     Pass --base <ref> to provide diff context
            Example: ai-check --mode NORMAL --base main

   Problem: "refusing to implement on 'main'"
   Fix:     Create a worktree first:
            git worktree add -b my-branch ../repo-suffix main
EOF
}

# ==========================================================================
# ai-help <command> — per-command help
# ==========================================================================

show_command_help() {
  local cmd="$1"
  # Strip ai- prefix if provided
  cmd="${cmd#ai-}"

  case "$cmd" in
    chat)
      echo "ai-chat [role]"
      echo
      echo "  Interactive Claude session with a role-based system prompt."
      echo "  Default role: architect"
      echo
      echo "  Available roles:"
      if [[ -d "$AI_DIR/roles" ]]; then
        for f in "$AI_DIR/roles"/*.md; do
          [[ -f "$f" ]] || continue
          echo "    $(basename "${f%.md}")"
        done
      fi
      echo
      echo "  Examples:"
      echo "    ai-chat                    # architect session"
      echo "    ai-chat planner            # planner session"
      echo "    ai-chat reviewer           # reviewer session"
      echo
      echo "  Alias: aic"
      ;;

    plan)
      echo "ai-plan"
      echo
      echo "  Read-only planning session using the planner role."
      echo "  May write plan.json to ai/out/ for ai-implement to consume."
      echo
      echo "  plan.json fields:"
      echo "    intent       Hints governance mode (e.g. \"patch\")"
      echo "    constraints  Reserved for future enforcement"
      echo
      echo "  Examples:"
      echo "    ai-plan                    # start planning session"
      echo
      echo "  Alias: aip"
      ;;

    implement)
      echo "ai-implement [claude args...]"
      echo
      echo "  Implementation session with automatic governance gating."
      echo
      echo "  Workflow:"
      echo "    1. Preflight: checks branch, detects merge base"
      echo "    2. Consumes plan.json if present (from ai-plan)"
      echo "    3. Launches interactive Claude session (implementer role)"
      echo "    4. On exit: computes diff profile, determines governance mode"
      echo "    5. Runs ai-check --mode <MODE> automatically"
      echo "    6. On failure: offers re-entry with findings injected"
      echo "    7. On pass: saves last.patch + last.report.json"
      echo
      echo "  Mode determination (precedence cascade):"
      echo "    HEAVY       >500 diff lines or >15 files"
      echo "    STRUCTURAL  multiple top-level dirs or renames"
      echo "    API         public surface paths touched"
      echo "    PATCH       plan intent=patch or <=3 files, no new/renames"
      echo "    NORMAL      default"
      echo
      echo "  Max iterations: 3 (preflight blocks main/master)"
      echo
      echo "  Examples:"
      echo "    ai-implement               # standard gated session"
      echo
      echo "  Alias: aii"
      ;;

    review)
      echo "ai-review"
      echo
      echo "  Codex-based tactical code review."
      echo "  Uses reviewer role + REVIEW_ARCHITECTURE.md."
      echo "  NOT structural validation (use ai-check for that)."
      echo
      echo "  Examples:"
      echo "    ai-review                  # start review session"
      echo
      echo "  Alias: air"
      ;;

    patch)
      echo "ai-patch \"<task description>\""
      echo
      echo "  Three-phase patch surgery workflow."
      echo
      echo "  Phases:"
      echo "    1. Patch Architecture  Claude plans scoped changes (patch-architect)"
      echo "    2. Patch Emission      Codex emits minimal diffs (patcher)"
      echo "    3. Validation          ai-check --bundle patch validates"
      echo
      echo "  Saves patch-plan.json to ai/out/ for audit trail."
      echo "  Requires both claude and codex."
      echo
      echo "  Examples:"
      echo "    ai-patch \"fix typo in README.md\""
      echo "    ai-patch \"add error handling to parse_config\""
      ;;

    skill)
      echo "ai-skill <name> [--version vX] [--scope path,...] [--base <ref>]"
      echo
      echo "  Run a single governance skill."
      echo "  Skills are non-interactive JSON validators invoked via Claude."
      echo
      echo "  Options:"
      echo "    --version vX           Override skill version"
      echo "    --scope path1,path2    Filter repo tree to paths"
      echo "    --base <ref>           Provide diff context (merge base)"
      echo
      echo "  Skill resolution (precedence):"
      echo "    1. Repo-local: <repo>/ai/skills/<name>/<version>/"
      echo "    2. Global:     dotfiles/ai/skills/<name>/<version>/"
      echo
      echo "  Output: unified JSON schema (skill, version, status, blocking,"
      echo "          major, warning, info)"
      echo "  Exit 1: if status=fail AND blocking is non-empty"
      echo
      echo "  Examples:"
      echo "    ai-skill repo-convention-enforcer"
      echo "    ai-skill scope-violation-detector --base main"
      echo "    ai-skill arch-index-alignment --scope ai/"
      ;;

    check)
      echo "ai-check [--mode <MODE>|--bundle <name>] [--scope path,...]"
      echo "         [--base <ref>] [--fail-fast]"
      echo
      echo "  Governance orchestrator. Runs multiple skills and reports results."
      echo
      echo "  Options:"
      echo "    --mode <MODE>          Route by mode (cost/mode-ordered)"
      echo "    --bundle <name>        Route by bundle (listing-ordered)"
      echo "    --diff-profile <json>  Diff profile; enables predicate filtering"
      echo "    --scope path1,path2    Filter repo tree to paths"
      echo "    --base <ref>           Provide diff context (merge base)"
      echo "    --fail-fast            Stop on first mandatory failure"
      echo
      echo "  --mode and --bundle are mutually exclusive."
      echo "  Default (no flags): --bundle default"
      echo
      echo "  Modes: PATCH, NORMAL, STRUCTURAL, API, HEAVY, AUDIT"
      echo
      echo "  Bundles:"
      if command -v yq >/dev/null 2>&1 && [[ -f "$AI_DIR/skills.yaml" ]]; then
        yq e '.bundles | keys | .[]' "$AI_DIR/skills.yaml" 2>/dev/null | sed 's/^/    /'
      else
        echo "    (install yq to list bundles)"
      fi
      echo
      echo "  Output: timestamped results in ai/out/<timestamp>/"
      echo "  Stable: ai/out/ai-check.json"
      echo "  Exit 1: if any mandatory skill has blocking findings"
      echo
      echo "  Examples:"
      echo "    ai-check --mode NORMAL --base main"
      echo "    ai-check --bundle patch --fail-fast --base main"
      echo "    ai-check --mode AUDIT --base main --scope src/"
      ;;

    list)
      echo "ai-list"
      echo
      echo "  List all registered skills, bundles, and roles."
      echo "  Skills show version, cost tier, and mandatory flag."
      echo "  Bundles show member skill lists."
      echo
      echo "  Examples:"
      echo "    ai-list"
      ;;

    help)
      echo "ai-help [command|workflows]"
      echo
      echo "  Display help for the AI governance toolkit."
      echo
      echo "  Forms:"
      echo "    ai-help                    Command overview"
      echo "    ai-help <command>          Per-command usage"
      echo "    ai-help workflows          Workflow recipes"
      echo
      echo "  Accepts both 'check' and 'ai-check' forms."
      echo
      echo "  Alias: aih"
      ;;

    install-hooks)
      echo "ai-install-hooks"
      echo
      echo "  Install a pre-push git hook that runs ai-check --bundle default."
      echo "  Push is blocked if any mandatory skill has blocking findings."
      echo "  Prompts before overwriting an existing hook."
      echo
      echo "  Examples:"
      echo "    ai-install-hooks"
      ;;

    migrate)
      echo "ai-migrate [/path/to/repo]"
      echo
      echo "  Five-phase migration scaffolder for onboarding repos."
      echo "  Defaults to current directory if no path given."
      echo
      echo "  Phases:"
      echo "    A. Scan        Detect directories, languages, existing docs"
      echo "    B. CLAUDE.md   Copy constitution template"
      echo "    C. Scaffolds   Create ai/skills/, ai/baselines/, ai/out/"
      echo "    D. Baselines   Optional directory/metrics snapshots"
      echo "    E. Validate    Run ai-check --bundle default"
      echo
      echo "  Examples:"
      echo "    ai-migrate                 # current directory"
      echo "    ai-migrate /path/to/repo   # specific repo"
      ;;

    *)
      echo "error: unknown command '$cmd'" >&2
      echo >&2
      echo "Available commands:" >&2
      echo "  $COMMANDS" >&2
      exit 1
      ;;
  esac
}

# ==========================================================================
# Main dispatch
# ==========================================================================

if [[ $# -eq 0 ]]; then
  show_overview
  exit 0
fi

case "$1" in
  workflows)
    show_workflows ;;
  -h|--help)
    show_overview ;;
  *)
    show_command_help "$1" ;;
esac
