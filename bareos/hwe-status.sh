#!/bin/bash
# Displays hardware encryption status

DEVICE="/dev/sg0"

hash bscrypto 2>/dev/null || { echo >&2 "You need to install bareos-storage-tape. Aborting."; exit 1; }

result=0
if ! bscrypto -d200 -e "${DEVICE}"; then
  result=1
fi

exit $result
