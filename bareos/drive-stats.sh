#!/bin/bash

DRIVE="/dev/sg0"
if [ ! -z "$1" ]; then
  DRIVE="$1"
fi

if [ ! -c "${DRIVE}" ]; then
  echo >&2 "ERROR: '$1' is not a valid block device."
  exit 1
fi

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo >&2 "This script must be run as root."
   exit 1
fi

STATUS=$(tapestat ${DRIVE})
REPORT=$(smartctl -H -l error ${DRIVE})

echo "${STATUS}"
echo "${REPORT}" | tail -n+3

exit 0
