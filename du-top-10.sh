#!/bin/bash
# find large files

TOP_10_MSG="top 10 by size"
if [ -n "$1" ]; then
  echo "$TOP_10_MSG: $1"
else
  echo "$TOP_10_MSG"
fi

du -hsx $1* \
  | sort -rh \
  | head -10
