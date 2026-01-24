# ==========================================================
# general: shell
# ==========================================================
alias .z='source $ZDOTDIR/.zshrc'            # reload your shell config
alias .ze='$EDITOR $ZDOTDIR/.zshrc_custom'   # edit your shell config
# edit + reload
alias .zer='$EDITOR "$ZDOTDIR/.zshrc_custom" && source "$ZDOTDIR/.zshrc"'

# ==========================================================
# general: safety / defaults
# ==========================================================
alias rm='rm -i'                             # confirm before delete
alias cp='cp -i'                             # confirm overwrite
alias mv='mv -i'                             # confirm overwrite


# ==========================================================
# general: ls / filesystem
# ==========================================================
alias ls='eza --icons'                       # modern ls
alias ll='eza -lah --icons'                  # long, all, human
alias la='eza -a --icons'                    # all files
alias tree='eza --tree --icons'              # directory tree


# ==========================================================
# general: viewing / search
# ==========================================================
alias cat='bat'                              # syntax-highlighted cat
alias grep='rg'                              # fast recursive grep
alias less='less -R'                         # raw color support


# ==========================================================
# general: navigation
# ==========================================================
alias cd='z'                                 # zoxide smart cd
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'


# ==========================================================
# general: system
# ==========================================================
alias df='df -h'                             # disk usage
alias du='du -h'                             # directory size
alias free='free -h'                         # memory usage
alias ff='fastfetch'                         # system information


# ==========================================================
# git: base
# ==========================================================
alias g='git'                                # base git command


# ==========================================================
# git: status / inspect
# ==========================================================
alias gs='git status'                        # working tree status
alias gd='git diff'                          # unstaged changes
alias gds='git diff --staged'                # staged changes


# ==========================================================
# git: add / commit
# ==========================================================
alias ga='git add'                           # stage files
alias gaa='git add --all'                    # stage all changes

alias gc='git commit'                        # commit (editor)
alias gcm='git commit -m'                    # commit with message
alias gca='git commit --amend'               # amend last commit
alias gcan='git commit --amend --no-edit'    # amend, keep message


# ==========================================================
# git: branches / checkout
# ==========================================================
alias gb='git branch'                        # list local branches
alias gba='git branch -a'                    # list all branches
alias gbd='git branch -d'                    # delete local branch

alias gco='git checkout'                     # switch branches / restore
alias gcb='git checkout -b'                  # create + switch branch


# ==========================================================
# git: update / sync
# ==========================================================
alias gl='git pull'                          # pull (repo-configured)
alias gpl='git pull'                         # explicit pull
alias gpr='git pull --rebase'                # rebase onto upstream
alias gprs='git pull --rebase --autostash'   # rebase with dirty tree
# full linear sync
alias gup='git fetch --all --prune && git rebase'
alias grabort='git rebase --abort'           # abort rebase


# ==========================================================
# git: push
# ==========================================================
alias gp='git push'                          # push to upstream
alias gpf='git push --force-with-lease'      # safe force push


# ==========================================================
# git: log / history
# ==========================================================
alias glog='git log --oneline --graph --decorate'        # compact history
alias gloga='git log --oneline --graph --decorate --all' # full repo history


# ==========================================================
# git: recovery / destructive
# ==========================================================
alias gundo='git reset --soft HEAD~1'        # undo last commit, keep changes
alias gdiscard='git checkout -- .'           # discard all local changes

# ==========================================================
# git: help / recall
# ==========================================================
galiases() {
  cat <<'EOF'
g        → git
           Base git command

gs       → git status
           Show working tree state
gd       → git diff
           Show unstaged changes
gds      → git diff --staged
           Show staged changes

ga       → git add
           Stage files
gaa      → git add --all
           Stage all changes

gc       → git commit
           Commit staged changes
gcm      → git commit -m
           Commit with inline message
gca      → git commit --amend
           Amend last commit
gcan     → git commit --amend --no-edit
           Amend, keep message

gb       → git branch
           List local branches
gba      → git branch -a
           List all branches
gbd      → git branch -d
           Delete local branch

gco      → git checkout
           Switch branches / restore files
gcb      → git checkout -b
           Create and switch branch

gl / gpl → git pull
           Pull using repo strategy
gpr      → git pull --rebase
           Rebase onto upstream
gprs     → git pull --rebase --autostash
           Rebase safely with local changes
gup      → git fetch --all --prune && git rebase
           Full sync, linear history
grabort  → git rebase --abort
           Abort rebase

gp       → git push
           Push to upstream
gpf      → git push --force-with-lease
           Safe force push

glog     → git log --oneline --graph --decorate
           Compact commit history
gloga    → git log --oneline --graph --decorate --all
           Full repository history

gundo    → git reset --soft HEAD~1
           Undo last commit, keep changes
gdiscard → git checkout -- .
           Discard all local changes
EOF
}

