#!/bin/bash
#
# -=[ 0x19e Networks ]=-
#
# Enables auto-commiting changes to a file that is already under Git control
#
FILE="$1"
MESSAGE="$2"

# display usage information and exit
function usage()
{
  echo >&2 "Usage: $0 <path> <message>"
  exit 1
}

# check required arguments
if [ -z "${FILE}" ] || [ -z "${MESSAGE}" ]; then
  usage
fi

# resolve parent directory
SOURCE="${FILE}"
if [ ! -d "$SOURCE" ]; then
  while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  ROOT="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
else
  ROOT="$SOURCE"
fi
if [ -z "${ROOT}" ]; then
  echo >&2 "ERROR: Failed to resolve parent directory for '${FILE}'."
  exit 1
fi

# git handling for etckeeper (check if /etc/.git exists)
if hash git 2>/dev/null; then
  pushd "${ROOT}" > /dev/null 2>&1
  if `git rev-parse --is-inside-work-tree > /dev/null 2>&1`; then
    if [[ "$(git status --porcelain -- ${FILE}|egrep '^(M| M)')" != "" ]]; then
      # commit pending changes
      git add --all "${FILE}"
      git commit -m "$MESSAGE"
    fi
  fi
  popd > /dev/null 2>&1
fi

exit 0
