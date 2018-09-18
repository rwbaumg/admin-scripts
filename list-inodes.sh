#!/bin/bash
# find directories with a lot of inodes

TOP_10_MSG="top 10 by inodes"
INPUT_PATH="."

if [ -n "$1" ]; then
  INPUT_PATH=$(readlink -m "$@")
  echo "$TOP_10_MSG: $INPUT_PATH"
else
  INPUT_PATH=$(readlink -m "$INPUT_PATH")
  echo "$TOP_10_MSG"
fi

find "${INPUT_PATH}" -xdev -printf '%h\n' \
  | sort \
  | uniq -c \
  | sort -k 1 -n -r \
  | head -40
