#!/bin/bash

# Houses all of the cloned-down repositories
export DEV_DIR="$HOME/Dev"

# Where this repo lives. Derived rather than hardcoded so a clone works from
# anywhere, and so the installer loop below can be anchored to it.
export KONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export grab="brew install"

missing() {
  ! [ -x "$(command -v "$1")" ]
}

# Ask brew about the one formula. Grepping a full `brew list` matched
# substrings, so git-delta and libgit2 both counted as git being installed.
missing_package() {
  ! brew list --versions "$1" > /dev/null 2>&1
}

ensure_package() {
  local package
  for package in "$@"; do
    if missing_package "$package"; then
      $grab "$package"
    fi
  done
}

# Ensures that a symlink exists from $2 to $1.
ensure_link() {
  local target="$1" link="$2"

  # A real file or directory here is somebody's data: ~/.vim holds every
  # installed plugin. Move it aside rather than removing it.
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    mv "$link" "$link.backup.$(date +%Y%m%d%H%M%S)"
  fi

  if [ ! -L "$link" ] || [ ! "$(readlink "$link")" -ef "$target" ]; then
    rm -f "$link"
    ln -s "$target" "$link"
  fi
}

# Looks for install scripts matching "install$1" in the config folders and runs
# them. Anchored to KONFIG_DIR: this used to glob a relative configs/*, so
# running the installer from anywhere but the repo root silently did nothing.
run_installers() {
  local suffix="$1" item installer
  local name="install${suffix:+_$suffix}"

  for item in "$KONFIG_DIR"/configs/*; do
    installer="$item/$name"
    [ -f "$installer" ] || continue
    . "$installer"
  done
}
