stty -ixon

### Git ###
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

export PS1='\[\e[93m\]\W \[\e[0;32m\]$(parse_git_branch)\$ \[\e[0m\] '
export VISUAL=vim
export EDITOR="$VISUAL"
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
  gh search repos org:wbd-streaming $1 in:name --json fullName --jq '.[].fullName' | fzf | xargs gh repo clone
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
complete -F __start_kubectl k
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
# TMUX
alias tn='tmux new -s $1'
alias ta='tmux attach-session -t $1'
alias tq='tmux kill-session -t $1'
alias td='tmux detach'
alias tl='tmux list-session'
# sourced from https://github.com/junegunn/fzf/wiki/examples#tmux
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
    fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}
