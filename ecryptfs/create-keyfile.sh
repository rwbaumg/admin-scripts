#!/bin/bash
# creates a new keyfile

# Load configuration
CONFIG=$(dirname $0)/config.sh
if ! [ -e "${CONFIG}" ]; then
  echo >&2 "ERROR: Missing configuration file '${CONFIG}'."
  exit 1
fi
source ${CONFIG}

if [ -e "${KEYFILE}" ]; then
  echo >&2 "ERROR: Key file '${KEYFILE}' already exists."
  exit 1
fi

echo "Creating new key file..."
if ! dd bs=512 count=8 if=/dev/random of="${KEYFILE}" iflag=fullblock; then
  echo >&2 "ERROR: Failed to create key file '${KEYFILE}'."
  exit 1
fi

echo "Wrote new key file to ${KEYFILE}."
exit 0
