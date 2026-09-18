stty -ixon

### Git ###
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

export VISUAL=vim
export EDITOR="$VISUAL"
export PS1="\[\e[32m\]\w\[\e[33m\]\$(parse_git_branch)\[\e[0m\] \$ "
### Files ###
killport() {
  lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs kill -9
}
md() {
  mkdir $1; cd $1
}

# purrty git log
gl() {
  git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
}

gr() {
  branch=$(git rev-parse --abbrev-ref HEAD)
  git remote update && git reset --hard origin/$branch
}

gsu() {
  git submodule update --init
}

gcr() {
  local repo
  repo=$(gh search repos org:wbd-streaming "$1" in:name --json fullName --jq '.[].fullName' | fzf)
  if [[ -n "$repo" ]]; then
    git clone "git@github.com-hbo:$repo.git"
  fi
}

grb() {
  git rebase origin/$1 -i
}

# kube stuff

## ALIASES ##
alias la='ls -A'
alias ll='ls -alhF --color=auto'
alias c='cd .. && pwd && ls'
# Kube
alias k='kubectl'
# Docker
alias dc='docker compose build $1'
alias dcp='docker container prune -f'
alias dcd='docker-compose down -v --rmi all --remove-orphans'
alias dsp='docker system prune'
alias dbp='docker builder prune' # clear build cache only
alias dcu='docker-compose up -d --force-recreate --renew-anon-volumes'
# Git 
alias g='git'
alias gs='git status'
alias gb='git branch'
alias ga='git add'
alias gp='git push origin HEAD'
alias v='vim'
# sourced from https://github.com/junegunn/fzf/wiki/examples
# fd - cd to selected directory
fd() {
  local dir
  dir=$(find ${1:-.} -maxdepth 3 -path '*/\.*' -prune \
    -o -type d -print 2> /dev/null | fzf +m) &&
    cd "$dir"
}

# fgb - checkout git branch (including remote branches)
# Lets you switch git branches via fuzzy search.
fgb() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" |
    fzf --height "$(( 2 + $(wc -l <<< "$branches") ))" +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}
export PATH="/opt/homebrew/bin:$PATH"
# ~/.local/bin (claude, etc). Lives here rather than in .bash_profile so that
# non-login interactive shells — `bash` inside a shell, cy panes, editor
# terminals — get it too; .bash_profile is only read by login shells.
export PATH="$HOME/.local/bin:$PATH"
# Go. Single toolchain from Homebrew; `go install` lands in $GOPATH/bin.
# No goenv: since Go 1.21 the `go` directive in each go.mod pins the toolchain
# and GOTOOLCHAIN=auto (the default) downloads it on demand, so per-project Go
# versions are handled by the repo itself. To force one: GOTOOLCHAIN=go1.22.12.
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# For GPG (if you're using GPG with git, e.g. commit signing)
export GPG_TTY=$(tty)
export KUBECONFIG=$KUBECONFIG:$(find $HOME/.kube/wbd -name '*kubeconfig' | xargs | sed 's/ /:/g')
source "$HOME/Dev/hbo/developer-tools/scripts/kube-helpers.sh"
source "$HOME/Dev/hbo/scripts/aws_login.sh"
source "$HOME/Dev/hbo/scripts/logs.sh"
export PATH='/Users/ajigjids/.duckdb/cli/latest':$PATH
export PATH="$HOME/Dev/hbo/scripts:$PATH"
# Personal scripts (aurora, etc.)
export PATH="$HOME/bin:$PATH"

# Standup notes -- `standup` for the latest day, `standup ls` to browse,
# `standup 08-12` for one day. Rendering is glow (brew install glow).
standup() {
  "$HOME/Dev/hbo/standup/bin/view.sh" "$@"
}
