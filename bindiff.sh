#!/bin/bash
# Peform a binary diff of two files using hexdump

hash diff 2>/dev/null || { echo >&2 "You need to install diff (diffutils). Aborting."; exit 1; }
hash hexdump 2>/dev/null || { echo >&2 "You need to install hexdump (bsdmainutils). Aborting."; exit 1; }

export HEXDUMP_ARGS="-C"
export DIFFCMD_ARGS="--color"

FILE1="$1"
FILE2="$2"

if [ -z "${FILE1}" ] || [ -z "${FILE2}" ]; then
  echo >&2 "Usage: $0 <file1> <file2>"
  exit 1
fi
if [ ! -e "${FILE1}" ]; then
  echo >&2 "ERROR: File '$FILE1' does not exist."
  exit 1
fi
if [ ! -e "${FILE2}" ]; then
  echo >&2 "ERROR: File '$FILE2' does not exist."
  exit 1
fi

# perform the actual diff
diff --color <(hexdump -C "${FILE1}") <(hexdump -C "${FILE2}")

exit 1
