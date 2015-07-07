#!/bin/bash
# broadcasts a message

if [[ -z "$1" ]]; then
  echo "Usage: $0 <string>" >&2
  exit 1
fi

TMP_FILE=/tmp/wall_msg

echo "$1" > $TMP_FILE
wall < $TMP_FILE
rm -f $TMP_FILE
