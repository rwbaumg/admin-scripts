#!/bin/bash
# print openssl info for a given site

if [[ -z "$1" ]]; then
  echo >&2 "Usage: $0 <server>"
  exit 1
fi

SERVER="$1"; \
echo QUIT | openssl s_client -connect $SERVER:443 \
                             -servername $SERVER \
                             -status 2> /dev/null \
