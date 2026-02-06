export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export SHELL="$(command -v zsh)"

setopt autocd
setopt correct
setopt extendedglob

# gastown — durable artifact system (see tools/gastown/)
export GASTOWN_HOME="$HOME/workspace/gastown"

# npm user-local global binaries (for tools like codex reviewer)
if [ -d "$HOME/.npm-global/bin" ]; then
  export PATH="$HOME/.npm-global/bin:$PATH"
fi

