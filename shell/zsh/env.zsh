export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export SHELL="$(command -v zsh)"

setopt autocd
setopt correct
setopt extendedglob

# go binaries and local tools
for _dir in "$HOME/go/bin" "$HOME/.local/bin"; do
  if [ -d "$_dir" ]; then
    export PATH="$_dir:$PATH"
  fi
done
unset _dir

# mise shims — in every zsh mode, so mise-installed tools (nvim, rg,
# starship, ...) also resolve in non-interactive shells
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh --shims)"
fi

# npm user-local global binaries (for tools like codex reviewer)
if [ -d "$HOME/.npm-global/bin" ]; then
  export PATH="$HOME/.npm-global/bin:$PATH"
fi

