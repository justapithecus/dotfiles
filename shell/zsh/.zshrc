# main interactive entrypoint

source "$ZDOTDIR/env.zsh"
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/completions.zsh"
source "$ZDOTDIR/compdefs.zsh"
source "$ZDOTDIR/keybindings.zsh"
source "$ZDOTDIR/word-jump.zsh"

# prompt + tools
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"


