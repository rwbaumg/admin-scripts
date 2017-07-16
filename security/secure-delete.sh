#!/bin/bash
# securely deletes a file

if [[ -z "$@" ]]; then
  echo "Usage: $0 <file> ..." >&2
  exit 1
fi

RND_SOURCE="/dev/urandom"
SHRED_TIMES=10

shred -v \
      --random-source "$RND_SOURCE" \
      --iterations "$SHRED_TIMES" \
      --zero \
      --remove \
      $@
