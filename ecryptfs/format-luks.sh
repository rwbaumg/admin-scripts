#!/bin/bash

hash cryptsetup 2>/dev/null || { echo >&2 "You need to install cryptsetup-bin. Aborting."; exit 1; }

# Load configuration
CONFIG=`dirname $0`/config.sh
if ! [ -e "${CONFIG}" ]; then
  echo >&2 "ERROR: Missing configuration file '${CONFIG}'."
  exit 1
fi
source ${CONFIG}

if [ ! -e "${STORAGE}" ]; then
  echo >&2 "ERROR: The container '${STORAGE}' does not exist."
  exit 1
fi

cryptsetup --verbose \
           --type plain \
           --align-payload=1 \
           --use-urandom \
           --verify-passphrase \
           --cipher ${CIPHER} \
           --key-size ${KEY_SIZE} \
           --hash ${HASH_ALG} \
           --iter-time ${ITER_TIME} \
           luksFormat ${STORAGE}

if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed to format LUKS container file '${STORAGE}'."
  exit 1
fi

exit 0
