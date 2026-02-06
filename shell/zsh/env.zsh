export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export SHELL="$(command -v zsh)"

setopt autocd
setopt correct
setopt extendedglob

# go binaries and local tools — gastown (gt), beads (bd), etc.
for _dir in "$HOME/go/bin" "$HOME/.local/bin"; do
  if [ -d "$_dir" ]; then
    export PATH="$_dir:$PATH"
  fi
done
unset _dir

# npm user-local global binaries (for tools like codex reviewer)
if [ -d "$HOME/.npm-global/bin" ]; then
  export PATH="$HOME/.npm-global/bin:$PATH"
fi

