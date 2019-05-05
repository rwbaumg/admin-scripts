#!/bin/bash

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }
hash cut 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }
hash grep 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }
hash sort 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }
hash uniq 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

# specify the git directory
GIT_DIR=$(pwd)

# check if an argument was provided
if [ $# -gt 0 ]; then
  if [ ! -z "$1" ]; then
    GIT_DIR=$1
  else
    echo >&2 "ERROR: Argument must not be null."
    exit 1
  fi
fi

if [ ! -e "$GIT_DIR" ]; then
  echo >&2 "'$GIT_DIR' does not exist."
  exit 1
fi

if ! $(git -C "$GIT_DIR" rev-parse); then
  echo >&2 "Directory does not appear to be a valid Git repository: $DIR"
  exit 1
fi

pushd "$GIT_DIR" 2>&1 >/dev/null

echo "Authors for $GIT_DIR:"

git log --pretty=full \
  | grep -Po '(Author|Commit): (.*)' \
  | cut -f '2-' -d ' ' \
  | sort \
  | uniq

popd 2>&1 >/dev/null

exit 0
