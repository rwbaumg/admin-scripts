#!/bin/bash
# Prints a variety of statistics for the specified tape drive

DRIVE="/dev/sg0"
if [ ! -z "$1" ]; then
  DRIVE="$1"
fi

if [ ! -c "${DRIVE}" ]; then
  echo >&2 "ERROR: '$1' is not a valid block device."
  exit 1
fi

STATUS=$(tapestat ${DRIVE})
if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed to read tape status from ${DRIVE}."
  exit 1
fi

REPORT=$(smartctl -i -H -l error ${DRIVE})
if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed to read S.M.A.R.T. status from ${DRIVE}."
  exit 1
fi

echo "${STATUS}"
echo "${REPORT}" | tail -n+3

exit 0
