#!/usr/bin/env bash
# Bash completion for ai-* commands

_ai_check_completions() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prev" in
    --bundle)
      local ai_dir
      ai_dir="$(cd "$(dirname "$(readlink -f "$(command -v ai-check 2>/dev/null || echo /dev/null)")")/.." 2>/dev/null && pwd)"
      if [[ -f "$ai_dir/skills.yaml" ]] && command -v yq >/dev/null 2>&1; then
        COMPREPLY=($(compgen -W "$(yq e '.bundles | keys | .[]' "$ai_dir/skills.yaml" 2>/dev/null)" -- "$cur"))
      fi
      return ;;
  esac

  COMPREPLY=($(compgen -W "--bundle --scope --fail-fast --help" -- "$cur"))
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
  ai_dir="$(cd "$(dirname "$(readlink -f "$(command -v ai-skill 2>/dev/null || echo /dev/null)")")/.." 2>/dev/null && pwd)"
  if [[ -f "$ai_dir/skills.yaml" ]] && command -v yq >/dev/null 2>&1; then
    COMPREPLY=($(compgen -W "$(yq e '.registry[].name' "$ai_dir/skills.yaml" 2>/dev/null) --version --scope" -- "$cur"))
  fi
}

_ai_chat_completions() {
  local cur
  cur="${COMP_WORDS[COMP_CWORD]}"

  # Complete role names
  local ai_dir
  ai_dir="$(cd "$(dirname "$(readlink -f "$(command -v ai-chat 2>/dev/null || echo /dev/null)")")/.." 2>/dev/null && pwd)"
  if [[ -d "$ai_dir/roles" ]]; then
    COMPREPLY=($(compgen -W "$(ls "$ai_dir/roles/"*.md 2>/dev/null | xargs -I{} basename {} .md)" -- "$cur"))
  fi
}

complete -F _ai_check_completions ai-check
complete -F _ai_skill_completions ai-skill
complete -F _ai_chat_completions ai-chat
