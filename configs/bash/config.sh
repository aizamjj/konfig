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
  mkdir -p "$1" && cd "$1"
}

# purrty git log
gl() {
  git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
}

# Discards every local commit and uncommitted change on the branch, so it asks
# first -- it sits one key away from gs.
gr() {
  local branch reply
  branch=$(git rev-parse --abbrev-ref HEAD) || return
  read -r -p "hard reset $branch to origin/$branch? [y/N] " reply
  [[ $reply == [yY] ]] || return 1
  git remote update && git reset --hard "origin/$branch"
}

gsu() {
  git submodule update --init
}

gcr() {
  local repo
  # gh has to be on the work account for the search half: gh auth switch -u.
  repo=$(gh search repos org:wbd-streaming "$1" in:name --json fullName --jq '.[].fullName' | fzf) || return
  if [[ -n "$repo" ]]; then
    git clone "git@github.com:$repo.git"
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
alias dc='docker compose build'
alias dcp='docker container prune -f'
alias dcd='docker compose down -v --rmi all --remove-orphans'
alias dsp='docker system prune'
alias dbp='docker builder prune' # clear build cache only
alias dcu='docker compose up -d --force-recreate --renew-anon-volumes'
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
  dir=$(find "${1:-.}" -maxdepth 3 -path '*/\.*' -prune \
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
# .bashrc runs for every interactive shell, so an unconditional prepend grew
# PATH by six entries each time. Add each directory once.
path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

path_prepend "/opt/homebrew/bin"
# ~/.local/bin (claude, etc). Lives here rather than in .bash_profile so that
# non-login interactive shells -- `bash` inside a shell, cy panes, editor
# terminals -- get it too; .bash_profile is only read by login shells.
path_prepend "$HOME/.local/bin"
# Go. Single toolchain from Homebrew; `go install` lands in $GOPATH/bin.
# No goenv: since Go 1.21 the `go` directive in each go.mod pins the toolchain
# and GOTOOLCHAIN=auto (the default) downloads it on demand, so per-project Go
# versions are handled by the repo itself. To force one: GOTOOLCHAIN=go1.22.12.
export GOPATH="$HOME/go"
path_prepend "$GOPATH/bin"
path_prepend "$HOME/.duckdb/cli/latest"
path_prepend "$HOME/Dev/hbo/scripts"
# Personal scripts (aurora, etc.)
path_prepend "$HOME/bin"
export PATH

# For GPG (if you're using GPG with git, e.g. commit signing)
export GPG_TTY=$(tty)

# Work helpers, guarded: this file is public and also runs on machines that
# have no ~/Dev/hbo.
for _helper in "$HOME/Dev/hbo/developer-tools/scripts/kube-helpers.sh" \
               "$HOME/Dev/hbo/scripts/aws_login.sh" \
               "$HOME/Dev/hbo/scripts/logs.sh"; do
  [ -f "$_helper" ] && source "$_helper"
done
unset _helper

# kube-helpers.sh sets KUBECONFIG itself, by appending to whatever it inherits.
# So a nested shell repeats the whole list, and an unset one starts it with a
# colon, which reads as an empty entry. Keep the first of each path, drop blanks.
if [ -n "${KUBECONFIG:-}" ]; then
  KUBECONFIG=$(printf '%s' "$KUBECONFIG" | tr ':' '\n' | awk 'NF && !seen[$0]++' | paste -sd: -)
  export KUBECONFIG
fi

# Standup notes -- `standup` for the latest day, `standup ls` to browse,
# `standup 08-12` for one day. Rendering is glow (brew install glow).
standup() {
  "$HOME/Dev/hbo/standup/bin/view.sh" "$@"
}
