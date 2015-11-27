#!/bin/bash
# invokes tcpdump on the specified interface

hash tcpdump 2>/dev/null || { echo >&2 "You need to install tcpdump. Aborting."; exit 1; }

if [[ -z "$1" ]] || [[ -z "$2" ]]; then
  echo "Usage: $0 <iface> <file>"
  exit 1
fi

tcpdump -nnXSs 1514 -w $2 -i $1
