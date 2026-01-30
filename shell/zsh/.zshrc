# main interactive entrypoint

# disable aliases in interactive shell
# this prevents issues with commands in AI agent sandboxes
if [[ ! -o interactive ]]; then
  setopt NO_ALIAS
fi

source "$ZDOTDIR/env.zsh"
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/completions.zsh"
source "$ZDOTDIR/compdefs.zsh"
source "$ZDOTDIR/keybindings.zsh"
source "$ZDOTDIR/word-jump.zsh"

# prompt + tools
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(mise activate zsh --shims)"


