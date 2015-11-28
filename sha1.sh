#!/bin/bash
# gets the sha1 hash of an input string

if [[ -z "$1" ]]; then
  echo "Usage: $0 <string>" >&2
  exit 1
fi

echo -n "$1" | sha1sum | awk '{print $1}'
