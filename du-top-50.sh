#!/bin/bash
# find large files

TOP_50_MSG="top 50 by size"
if [ -n "$1" ]; then
  echo "$TOP_50_MSG: $1"
else
  echo "$TOP_50_MSG"
fi

du -hsx $1* \
  | sort -rh \
  | head -50
