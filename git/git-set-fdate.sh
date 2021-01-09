#!/bin/bash
# Set file modification times to date of last commit.

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

if ! git -C . rev-parse; then
  echo >&2 "Directory does not appear to be a valid Git repository."
  exit 1
fi

IFS="
"
for FILE in $(git ls-files)
do
    TIME=$(git log --pretty=format:%cd -n 1 --date=iso -- "$FILE")
    TIME=$(date -d "$TIME" +%Y%m%d%H%M.%S)
    touch -m -t "$TIME" "$FILE"
done

exit 0
