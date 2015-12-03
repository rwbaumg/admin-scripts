#!/bin/bash
# find large files

TOP_20_MSG="top 20 by size"
INPUT_PATH="."

if [ -n "$1" ]; then
  INPUT_PATH=$(readlink -m "$@")
  echo "$TOP_20_MSG: $INPUT_PATH"
else
  INPUT_PATH=$(readlink -m "$INPUT_PATH")
  echo "$TOP_20_MSG"
fi

du -hsx "${INPUT_PATH}"/* \
  | sort -rh \
  | head -20
