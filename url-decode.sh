#!/bin/bash
# decodes a url using built-in python method
# rwb[at]0x19e[dot]net

hash python 2>/dev/null || { echo >&2 "You need to install python. Aborting."; exit 1; }

INPUT="$1"

if [[ -z "$INPUT" ]]; then
  echo >&2 "Usage: $0 <encoded_url>"
  exit 0
fi

python -c "import sys, urllib as ul; print ul.unquote_plus(\"$INPUT\")"

exit 0
