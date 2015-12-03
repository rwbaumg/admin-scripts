#!/bin/bash
# find large files

TOP_10_MSG="top 10 by size"
INPUT_PATH="."

if [ -n "$1" ]; then
  INPUT_PATH=$(readlink -m "$@")
  echo "$TOP_10_MSG: $INPUT_PATH"
else
  INPUT_PATH=$(readlink -m "$INPUT_PATH")
  echo "$TOP_10_MSG"
fi

du -hsx "${INPUT_PATH}"/* \
  | sort -rh \
  | head -10
