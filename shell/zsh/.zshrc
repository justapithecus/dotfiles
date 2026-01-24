# main interactive entrypoint

source "$ZDOTDIR/env.zsh"
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/completions.zsh"

# user overrides
[[ -f "$ZDOTDIR/.zshrc_custom" ]] && source "$ZDOTDIR/.zshrc_custom"

# prompt + tools
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

