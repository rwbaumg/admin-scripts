#!/bin/bash
# performs a zone transfer using dig
# lazy; expects command in the format of './dig-do-transfer.sh example.com @8.8.8.8'

if [[ -z "$1" || -z "$2" ]]; then
  echo "Usage: $0 [domain] [@local-server]" >&2
  exit 1
fi

dig $2 $1 axfr
