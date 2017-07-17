#!/bin/bash
# determine if a server has ocsp stapling enabled
# produces no output if server does not use or has
# incorrectly configured OCSP stapling.

if [[ -z "$1" ]]; then
  echo >&2 "Usage: $0 <server>"
  exit 1
fi

SERVER="$1"; \
echo QUIT | openssl s_client -connect $SERVER:443 \
                             -servername $SERVER \
                             -status 2> /dev/null \
          | grep -A 17 'OCSP response:' \
          | grep --color=never -B17 -A1 'This Update'
