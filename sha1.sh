#!/bin/bash
# gets the sha1 hash of an input string

if [ -z "$1" ]; then
  cat | sha1sum | awk '{printf "\n%s\n\n", $1}'
else
  echo -n "$1" | sha1sum | awk '{printf "\n%s\n\n", $1}'
fi
