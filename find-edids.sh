#!/bin/bash
# Find and display available EDIDs

DIR_NAME="/sys"
FILENAME="edid"

FOUND_EDID=0
EDID_ROKAY=0
while read -r line; do
  echo "$line";
  if ! raw_edid=$(hexdump -C "$line"); then
    echo >&2 "WARNING: Failed to read EDID: ${line}";
  fi
  FOUND_EDID=1
  if [ ! -z "${raw_edid}" ]; then
    echo "${raw_edid}";
    EDID_ROKAY=1;
  fi
done < <(find "${DIR_NAME}" -name "${FILENAME}" 2>/dev/null)

if [ "${FOUND_EDID}" -ne "0" ]; then
  if [ "${EDID_ROKAY}" -eq "0" ]; then
    echo >&2 "ERROR: Failed to read any available EDIDs."
    exit 1
  fi
else
  echo >&2 "ERROR: Failed to locate any EDIDs under ${DIR_NAME}."
  exit 1
fi

exit 0
