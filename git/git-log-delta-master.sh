#!/bin/bash
# Displays a list of commits only found in the specified branch

if [ -z "$1" ]; then
  echo >&2 "usage: $0 <branch>"
  exit 1
fi

git log --oneline --cherry-pick --no-merges --right-only master..."$1"

exit 0
