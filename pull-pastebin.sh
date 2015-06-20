#!/bin/bash
# Gets a raw paste from PasteBin

# check if curl command exists
hash curl 2>/dev/null || { echo >&2 "You need to install curl. Aborting."; exit 1; }

if [[ -z "$1" ]]; then
  echo "Usage: $0 <paste id>" >&2
  exit 1
fi

# TODO: Validate paste id using regex
PASTE_ID=$(echo "$1" | tr -d [:cntrl:][:punct:][:space:])
if [[ -z "$PASTE_ID" ]]; then
  echo "Fatal: Filtered paste id is null." >&2
  exit 1
fi

# load the raw paste
RAW_PASTE=$(curl -Ls "http://pastebin.com/raw.php?i=$PASTE_ID")

echo -e "$RAW_PASTE"
