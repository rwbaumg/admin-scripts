#!/bin/bash
# Prints a variety of statistics for the specified tape drive

hash tapestat 2>/dev/null || { echo >&2 "You need to install sysstat. Aborting."; exit 1; }
hash smartctl 2>/dev/null || { echo >&2 "You need to install smartmontools. Aborting."; exit 1; }

DRIVE="/dev/sg0"
if [ -n "$1" ]; then
  DRIVE="$1"
fi

if [ ! -c "${DRIVE}" ]; then
  echo >&2 "ERROR: '$1' is not a valid block device."
  exit 1
fi

if ! STATUS=$(tapestat ${DRIVE}); then
  echo >&2 "ERROR: Failed to read tape status from ${DRIVE}."
  exit 1
fi

if ! REPORT=$(smartctl -i -H -l error ${DRIVE}); then
  echo >&2 "ERROR: Failed to read S.M.A.R.T. status from ${DRIVE}."
  exit 1
fi

echo "${STATUS}"
echo "${REPORT}" | tail -n+3

exit 0
