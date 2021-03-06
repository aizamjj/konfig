#!/bin/bash

# Houses all of the cloned-down repositories
export DEV_DIR="$HOME/Dev"
export KONFIG_DIR="$HOME/konfig"

export grab="brew install"

no_need() {
  echo "No need to $1."
}

missing() {
  ! [ -x "$(command -v $1)" ]
}

missing_package() {
  ! brew list | grep "$1" > /dev/null 2>&1
}

ensure_package() {
  if missing_package "$1"; then
    $grab "$1"
  fi
}

# Ensures that a symlink exists from $2 to $1.
ensure_link() {
  if [ ! -L "$2" ] || [ ! "$(readlink $2)" -ef "$1" ]; then
    rm -rf "$2"
    ln -s "$1" "$2"
  fi
}

# Looks for install scripts matching "install$1" in the
# config folders and runs them.
install() {
  installer_name="install"

  if [ ! -z "$1" ]; then
    installer_name+="_$1"
  fi

  for item in configs/*; do
    [ -e "$item" ] || [ -d "$item" ] || continue

    INSTALLER="$item/$installer_name"

    if [ ! -f "$INSTALLER" ]; then
      continue
    fi

    . $INSTALLER
  done
}
