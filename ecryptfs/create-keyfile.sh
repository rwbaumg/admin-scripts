#!/bin/bash
# creates a new keyfile

RNG_DEV="/dev/urandom"

# Load configuration
CONFIG=$(dirname "$0")/config.sh
if ! [ -e "${CONFIG}" ]; then
  echo >&2 "ERROR: Missing configuration file '${CONFIG}'."
  exit 1
fi
# shellcheck source=/dev/null
source "${CONFIG}"

if [ ! -e "${RNG_DEV}" ]; then
  echo >&2 "ERROR: RNG device '${RNG_DEV}' does not exist."
  exit 1
fi
if [ -e "${KEYFILE}" ]; then
  echo >&2 "ERROR: Key file '${KEYFILE}' already exists."
  exit 1
fi

echo "Creating new key file..."
if ! dd bs=512 count=8 if="${RNG_DEV}" of="${KEYFILE}" iflag=fullblock; then
  echo >&2 "ERROR: Failed to create key file '${KEYFILE}'."
  exit 1
fi

echo "Wrote new key file to ${KEYFILE}."
exit 0
