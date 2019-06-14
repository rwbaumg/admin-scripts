#!/bin/bash

hash cryptsetup 2>/dev/null || { echo >&2 "You need to install cryptsetup-bin. Aborting."; exit 1; }

# Load configuration
CONFIG=$(dirname "$0")/config.sh
if ! [ -e "${CONFIG}" ]; then
  echo >&2 "ERROR: Missing configuration file '${CONFIG}'."
  exit 1
fi
source "${CONFIG}"

sudo umount "${MNTPATH}"
sudo cryptsetup close "${DEVNAME}"

exit 0
