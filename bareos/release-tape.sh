#!/bin/bash
# release tape storage
#
STORAGE="Tape"

hash bconsole 2>/dev/null || { echo >&2 "You need to install bareos-bconsole. Aborting."; exit 1; }

# Use bconsole to release storage
if ! OUTPUT=$(bconsole << END_OF_DATA
@output /dev/null
@output
release storage=${STORAGE}
quit
END_OF_DATA
); then
  echo >&2 "ERROR: Failed to release ${STORAGE} storage."
  if [ -n "${OUTPUT}" ]; then
    echo >&2 "ERROR: Command output: ${OUTPUT}"
  fi
  exit 1
fi

exit 0
