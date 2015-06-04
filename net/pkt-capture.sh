#!/bin/bash

if [[ -z "$1" ]] || [[ -z "$2" ]]; then
  echo "Usage: $0 <iface> <file>"
  exit 1
fi

tcpdump -nnXSs 1514 -w $2 -i $1
