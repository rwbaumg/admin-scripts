#!/bin/bash
# Print a file excluding comments

if [[ -z "$1" ]]; then
  echo "Usage: $0 <file>"
  exit 1
fi

# check valid file
if [ ! -f "$1" ]; then
  echo "File does not exist: $1" >&2
  exit 1
fi

grep -v '^$\|^\s*\#' "$1"
