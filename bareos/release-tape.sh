#!/bin/bash
# release tape storage
#
STORAGE="Tape"

hash bconsole 2>/dev/null || { echo >&2 "You need to install bareos-bconsole. Aborting."; exit 1; }

# Use bconsole to release storage
bconsole <<END_OF_DATA 2>&1 >/dev/null
@output /dev/null
@output
release storage=${STORAGE}
quit
END_OF_DATA

# Check to make sure the command succeeded
if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed to release ${STORAGE} storage."
  exit 1
fi

exit 0
