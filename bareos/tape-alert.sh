#!/bin/bash
#
# 0x19e Networks <http://0x19e.net/>
#
# Isolates SMART errors for a tape drive for conditional reporting
#
# Robert W. Baumgartner <rwb@0x19e.net>
#
DRIVE="/dev/sg0"
if [ ! -z "$1" ]; then
  DRIVE="$1"
fi

if [ ! -c "${DRIVE}" ]; then
  echo >&2 "ERROR: '$1' is not a valid block device."
  exit 1
fi

hash smartctl 2>/dev/null || { echo >&2 "You need to install smartmontools. Aborting."; exit 1; }

if ! OUTPUT=$(smartctl -H ${DRIVE}); then
  echo >&2 "ERROR: Failed to read S.M.A.R.T. status from ${DRIVE}."
  exit 1
fi

ALERT=$(echo "${OUTPUT}" | tail -n+5 | cut -d ':' -f2 | awk '{$1=$1};1')
if [ ! -z "${ALERT}" ] && [ "${ALERT}" != "OK" ]; then
  # Error detected
  echo "Tape alert: ${ALERT}"
  exit 1
fi

# No errors detected
exit 0
