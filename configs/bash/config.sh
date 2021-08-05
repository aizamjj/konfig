stty -ixon

export PS1="[\[\e[38;5;118m\]\t\[\e[0m\]] \[\e[38;5;182m\]\W\[\e[0m\]\n🐎\[\e[38;5;105m\]\$(parse_git_branch)\[\e[00m\]$ "

# create directory for personal scripts
export PATH="$HOME/bin:$PATH"

# find and kill port
killport() {
  lsof -i TCP:$1 | grep LISTEN | awk '{print $2}' | xargs kill -9
}

### Git ###
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
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

gnb() {
  git checkout -b aj/$(date +'%d-%m-%y')/$1
}

grb() {
  git rebase origin/master
}

source /users/aizam/git-completion.bash
# styled man pages
source ./users/aizam/.dot-config/most.sh

### ALIASES ###
alias la='ls -A'
alias c='cd .. && pwd && ls'
md() {
  mkdir $1; cd $1
}
# Git 
alias g='git'
alias gs='git status'
alias gb='git branch'
alias ga='git add'
alias gh='git checkout -b'
alias gc='git commit'
alias gp='git push origin HEAD'
alias v='vim'
# TMUX
alias tn='tmux new -s $1'
alias ta='tmux attach-session -t $1'
alias td='tmux kill-session -t $1'
