#!/bin/bash
# Finds whitespace in the specified document.

if [ -z ${1} ]; then
  echo >&2 "Usage: $0 <file-pattern>"
  exit 1
fi

grep -Pn "^.*([\t|\s|\b]+)$" ${1}

exit 0
