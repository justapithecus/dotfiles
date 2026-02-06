export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export SHELL="$(command -v zsh)"

setopt autocd
setopt correct
setopt extendedglob

# go binaries — gastown (gt) and other go-installed tools
if [ -d "$HOME/go/bin" ]; then
  export PATH="$HOME/go/bin:$PATH"
fi

# npm user-local global binaries (for tools like codex reviewer)
if [ -d "$HOME/.npm-global/bin" ]; then
  export PATH="$HOME/.npm-global/bin:$PATH"
fi

