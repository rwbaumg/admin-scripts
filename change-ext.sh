#!/bin/bash
# script to change file extensions

if [ "$#" -ne 3 ]; then
  echo >&2 "Usage: $0 <path> <ext> <new_ext>"
  exit 1
fi

echo "Updating extensions in $1 ..."
echo "Converting $2 -> $3"

for f in *.$2; do
  mv -v "$f" "$(basename "$f" .$2).$3"
done

exit 0
