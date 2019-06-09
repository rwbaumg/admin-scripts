#!/bin/bash
# creates an image of a CD/DVD disk
# rwb[at]0x19e.net

# specify the CD/DVD drive
DRIVE=/dev/cdrom
OUTPUT=""

if [ -n "${1}" ]; then
  if [ "${1}" == "-h" ] || [ "${1}" == "--help" ]; then
    echo "Usage: $0 [drive] [output]"
    exit 1
  fi
  DRIVE="${1}"
fi
if [ -n "${2}" ]; then
  OUTPUT="${2}"
fi

if [ ! -b "${DRIVE}" ]; then
  echo >&2 "ERROR: Optical drive '${DRIVE}' does not exist. Check hardware and drivers for errors."
  exit 1
fi

# check if superuser
if [ $EUID -eq 0 ]; then
   echo >&2 "ERROR: This script should not be run as root."
   exit 1
fi

# check if a disk is inserted
if ! blkid "$DRIVE" > /dev/null 2>&1; then
  echo >&2 "ERROR: No disk found on $DRIVE"
  exit 1
fi

# get some information about the inserted disk
LABEL=$(blkid "$DRIVE" | sed -n 's/.*LABEL=\"\([^\"]*\)\".*/\1/p' | sed -e 's/ /_/g')
SIZE=$(blockdev --getsize64 "$DRIVE")

if [ -z "${OUTPUT}" ]; then
  OUTPUT=$(readlink -f "$LABEL".iso)
fi
if [ -e "${OUTPUT}" ]; then
  echo >&2 "ERROR: File '${OUTPUT}' already exists (will not overwrite)."
  exit 1
fi

# get the size in megabytes
SIZE_IN_MB=$((SIZE/1024/1024))

echo "Ripping $LABEL ($SIZE_IN_MB MB) from drive ${DRIVE}"
echo "Writing image to $OUTPUT ..."

# create an image
dd if="$DRIVE" | pv -brtep -s "$SIZE" | dd of="$OUTPUT"

# eject the disk
eject "$DRIVE"

echo "Image saved to $OUTPUT"

exit 0
