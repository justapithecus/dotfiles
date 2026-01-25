export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export SHELL="$(command -v zsh)"

setopt autocd
setopt correct
setopt extendedglob

# npm user-local global binaries (for tools like codex)
if [ -d "$HOME/.npm-global/bin" ]; then
  export PATH="$HOME/.npm-global/bin:$PATH"
fi

