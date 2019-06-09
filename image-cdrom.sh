#!/bin/bash
# creates an image of a CD/DVD disk
# rwb[at]0x19e.net

# specify the CD/DVD drive
DRIVE=/dev/cdrom
OUTPUT=""

if [ -n "${1}" ]; then
  if [ "${1}" == "-h" ] || [ "${1}" == "--help" ]; then
    echo "Usage: $0 [output] [drive]"
    exit 1
  fi
  OUTPUT="${1}"
fi
if [ -n "${2}" ]; then
  DRIVE="${2}"
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
  echo >&2 "ERROR: No disk found in $DRIVE"
  exit 1
fi

# get some information about the inserted disk
if ! LABEL=$(blkid "$DRIVE" | sed -n 's/.*LABEL=\"\([^\"]*\)\".*/\1/p' | sed -e 's/ /_/g'); then
  echo >&2 "ERROR: Failed to determine label for media in ${DRIVE}"
  exit 1
fi
if ! SIZE=$(blockdev --getsize64 "$DRIVE"); then
  echo >&2 "ERROR: Failed to determine block size of media in ${DRIVE}"
  exit 1
fi

if [ -z "${OUTPUT}" ]; then
  if ! OUTPUT=$(readlink -f "$LABEL".iso); then
    echo >&2 "ERROR: Failed to generate output file name."
    exit 1
  fi
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
if ! dd if="$DRIVE" | pv -brtep -s "$SIZE" | dd of="$OUTPUT"; then
  echo >&2 "ERROR: Failed to create image."
  if [ -e "${OUTPUT}" ]; then
    rm -v "${OUTPUT}"
  fi
  exit 1
fi

# eject the disk
echo "Ejecting ${DRIVE} ..."
if ! eject "$DRIVE"; then
  echo >&2 "WARNING: Failed to eject ${DRIVE}"
fi

echo "Image saved to $OUTPUT"
exit 0
