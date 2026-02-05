# ------------------------------------------------------------------------------
# Zsh entrypoint
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Automation / agent safety
# Disable alias expansion in non-interactive shells (CI, Codex, Claude, etc.)
# Aliases may still be defined later, but will never expand.
# ------------------------------------------------------------------------------
if [[ ! -o interactive ]]; then
  setopt NO_ALIASES
fi

# ------------------------------------------------------------------------------
# Core environment (safe for all shells)
# ------------------------------------------------------------------------------
source "$ZDOTDIR/env.zsh"

# ------------------------------------------------------------------------------
# Interactive-only ergonomics
# ------------------------------------------------------------------------------
if [[ -o interactive ]]; then
  source "$ZDOTDIR/aliases.zsh"
  source "$ZDOTDIR/completions.zsh"
  source "$ZDOTDIR/compdefs.zsh"
  source "$ZDOTDIR/keybindings.zsh"
  source "$ZDOTDIR/word-jump.zsh"
fi

# ------------------------------------------------------------------------------
# Prompt & tool initialization (interactive only)
# ------------------------------------------------------------------------------
if [[ -o interactive ]]; then
  eval "$(starship init zsh)"
  eval "$(zoxide init zsh)"
  eval "$(mise activate zsh --shims)"
fi

# ------------------------------------------------------------------------------
# Local machine overrides (untracked secrets, host-specific settings)
# ------------------------------------------------------------------------------
[[ -f "$ZDOTDIR/.zshrc_custom" ]] && source "$ZDOTDIR/.zshrc_custom"
