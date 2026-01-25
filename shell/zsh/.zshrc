# main interactive entrypoint

source "$ZDOTDIR/env.zsh"
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/completions.zsh"
source "$ZDOTDIR/keybindings.zsh"

# prompt + tools
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
