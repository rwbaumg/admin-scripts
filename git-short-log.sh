#!/bin/bash
# Displays a short-log of the current branch

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a syml$
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the pa$
  # the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# TODO: Support input Git dir argument
# GIT_DIR=""

GIT_DIR=$(pwd)

if [ "$(dirname $0)" = "$GIT_DIR" ]; then
  echo >&2 "This script must be run from within a valid Git repository."
  exit 1
fi

if ! `git -C "$GIT_DIR" rev-parse`; then
  echo >&2 "Directory does not appear to be a valid Git repository: $DIR"
  exit 1
fi

pushd "$GIT_DIR" 2>&1 >/dev/null
git log -n 10 --format="%h %s"
popd 2>&1 >/dev/null

exit 0
