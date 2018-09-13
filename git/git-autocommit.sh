#!/bin/bash
# Enables auto-commiting changes to a file that is already under Git control

FILE="$1"
MESSAGE="$2"

function usage()
{
  echo >&2 "Usage: $0 <path> <message>"
  exit 1
}

if [ -z "${FILE}" ] || [ -z "${MESSAGE}" ]; then
  usage
fi

echo "Filename = $FILE"
echo "Message  = $MESSAGE"

SOURCE="${FILE}"
#SELF="${BASH_SOURCE[0]}"
if [ ! -d "$SOURCE" ]; then
  # resolve $SOURCE until the file is no longer a symlink
  while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    # if $SOURCE was a relative symlink, we need to resolve it relative to the path where
    # the symlink file was located
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    echo "src=$SOURCE"
  done
  echo "source=$SOURCE"
  ROOT="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
else
  ROOT="$SOURCE"
fi

# git handling for etckeeper (check if /etc/.git exists)
if hash git 2>/dev/null; then
  pushd "${ROOT}" > /dev/null 2>&1
  if `git rev-parse --is-inside-work-tree > /dev/null 2>&1`; then
    if [[ "$(git --work-tree=\"${ROOT}\" status --porcelain -- ${FILE}|egrep '^(M| M)')" != "" ]]; then
      echo git add "${FILE}"
      echo git commit -m "$MESSAGE"
    fi
  fi
  popd > /dev/null 2>&1
fi

exit 0
