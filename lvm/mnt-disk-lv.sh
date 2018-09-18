#!/bin/bash
# Mounts a logical volume containing a whole disk (i.e. multiple partitions)
# Uses kpartx to manage block device mappings

hash kpartx 2>/dev/null || { echo >&2 "You need to install kpartx. Aborting."; exit 1; }

VOLUME="$1"
if [ -z "$1" ]; then
   echo >&2 "Usage: $0 <lv-path>"
   exit 1
fi

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo >&2 "This script must be run as root."
   exit 1
fi

# Determine mappings that will be generated by kpartx
KPARTX_LIST=`kpartx -l ${VOLUME} | awk '{ print $1 }'`
if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed to determine kpartx mappings for ${VOLUME}."
  exit 1
fi
declare -a mappings=();
for part in ${KPARTX_LIST}; do
  map="/dev/mapper/${part}"
  mappings=("${mappings[@]}" "${map}")
done

# Create mappings
if ! kpartx -as ${VOLUME}; then
  echo >&2 "ERROR: Failed to create mappings for ${VOLUME}."
  exit 1
fi

# Print out mappings
for ((idx=0;idx<=$((${#mappings[@]}-1));idx++)); do
  map=${mappings[$idx]}
  dev=$(readlink -e ${map})
  if [ ! -b "$dev" ]; then
    echo >&2 "WARNING: '${map}' does not point to a valid block device."
  fi

  echo "${map}"
done

# TODO: Processing?

# Delete mappings
if ! kpartx -ds ${VOLUME}; then
  echo >&2 "ERROR: Failed to delete mappings for ${VOLUME}."
  exit 1
fi

exit 0
