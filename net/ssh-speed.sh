#!/bin/bash
# script to test speed of ssh connection

hash ssh 2>/dev/null || { echo >&2 "You need to install SSH. Aborting."; exit 1; }
hash pv 2>/dev/null || { echo >&2 "You need to install the Pipe Viewer ('pv') utility. Aborting."; exit 1; }

if [[ -z "$1" ]]; then
  echo "Usage: $0 <host>"
  exit 1
fi

# note: compression is enabled using -C
yes | pv | ssh -C $1 "cat > /dev/null"
