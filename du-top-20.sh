#!/bin/bash
# find large files

TOP_20_MSG="top 20 by size"
if [ -n "$1" ]; then
  echo "$TOP_20_MSG: $1"
else
  echo "$TOP_20_MSG"
fi

du -hsx $1* \
  | sort -rh \
  | head -20
