#!/usr/bin/env bash
# Bash completion for ai-* commands

# Resolve ai/ directory from command path or install breadcrumb
_ai_resolve_dir() {
  local cmd="$1" cmd_path dir
  cmd_path="$(command -v "$cmd" 2>/dev/null)" || return 1
  dir="$(cd "$(dirname "$cmd_path")/.." 2>/dev/null && pwd)"
  if [[ -f "$dir/CLAUDE.md" ]]; then
    echo "$dir"
  elif [[ -f "$(dirname "$cmd_path")/.ai-source" ]]; then
    cat "$(dirname "$cmd_path")/.ai-source"
  else
    return 1
  fi
}

_ai_check_completions() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prev" in
    --bundle)
      local ai_dir
      ai_dir="$(_ai_resolve_dir ai-check)" || return
      if [[ -f "$ai_dir/skills.yaml" ]] && command -v yq >/dev/null 2>&1; then
        COMPREPLY=($(compgen -W "$(yq e '.bundles | keys | .[]' "$ai_dir/skills.yaml" 2>/dev/null)" -- "$cur"))
      fi
      return ;;
  esac

  COMPREPLY=($(compgen -W "--bundle --scope --base --fail-fast --help" -- "$cur"))
}

_ai_skill_completions() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prev" in
    --version|--scope)
      return ;;
  esac

  # Complete skill names from registry
  local ai_dir
  ai_dir="$(_ai_resolve_dir ai-skill)" || return
  if [[ -f "$ai_dir/skills.yaml" ]] && command -v yq >/dev/null 2>&1; then
    COMPREPLY=($(compgen -W "$(yq e '.registry[].name' "$ai_dir/skills.yaml" 2>/dev/null) --version --scope" -- "$cur"))
  fi
}

_ai_chat_completions() {
  local cur
  cur="${COMP_WORDS[COMP_CWORD]}"

  # Complete role names
  local ai_dir
  ai_dir="$(_ai_resolve_dir ai-chat)" || return
  if [[ -d "$ai_dir/roles" ]]; then
    COMPREPLY=($(compgen -W "$(ls "$ai_dir/roles/"*.md 2>/dev/null | xargs -I{} basename {} .md)" -- "$cur"))
  fi
}

complete -F _ai_check_completions ai-check
complete -F _ai_skill_completions ai-skill
complete -F _ai_chat_completions ai-chat
