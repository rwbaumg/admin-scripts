#!/bin/bash
# Clean and reset all submodules and unversion files

# To delete all directories:
#  git submodule | cut -c43- | while read -r line; do (rm -rf "$line"); done

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

if ! git -C . rev-parse; then
  echo >&2 "Directory does not appear to be a valid Git repository."
  exit 1
fi

if ! git clean -xfd; then
  echo >&2 "Failed to clean folder."
  exit 1
fi

if ! git submodule foreach --recursive git clean -xfd; then
  echo >&2 "Failed to clean Git submodules."
  exit 1
fi

if ! git reset --hard; then
  echo >&2 "Failed to reset Git repository."
  exit 1
fi

if ! git submodule foreach --recursive git reset --hard; then
  echo >&2 "Failed to reset Git submodules."
  exit 1
fi

if ! git submodule update --init --recursive; then
  echo >&2 "Failed to initialize Git submodules."
  exit 1
fi

exit 0
