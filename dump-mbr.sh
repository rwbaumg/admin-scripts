#!/bin/bash

hash xxd 2>/dev/null || { echo >&2 "You need to install xxd. Aborting."; exit 1; }
hash dd 2>/dev/null || { echo >&2 "You need to install dd. Aborting."; exit 1; }

# check if superuser
if [[ $EUID -ne 0 ]]; then
  echo >&2 "This script must be run as root."
  exit 1
fi

if [ ! -z "$1" ]; then
  DEVICE="$1"
fi

if [ -z "${DEVICE}" ]; then
  DEVICE="/dev/sda"
fi

if [ ! -b "${DEVICE}" ]; then
  echo >&2 "ERROR: ${DEVICE} is not a valid block device."
  exit 1
fi

# dump MBR from device
echo "Dumping MBR from device ${DEVICE} ..."
if ! dd if="${DEVICE}" bs=512 count=1 2>/dev/null | xxd; then
  echo >&2 "ERROR: Failed to dump first 512 blocks from device ${DEVICE}"
  exit 1
fi

exit 0
