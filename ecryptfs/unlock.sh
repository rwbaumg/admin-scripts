#!/bin/bash
# Unlocks cryptfs storage.

hash cryptsetup 2>/dev/null || { echo >&2 "You need to install cryptsetup-bin. Aborting."; exit 1; }

# Load configuration
CONFIG=$(dirname "$0")/config.sh
if ! [ -e "${CONFIG}" ]; then
  echo >&2 "ERROR: Missing configuration file '${CONFIG}'."
  exit 1
fi
source "${CONFIG}"

if [ ! -e "${STORAGE}" ]; then
  echo >&2 "ERROR: Storage file '${STORAGE}' does not exist."
  exit 1
fi
if [ ! -e "${MNTPATH}" ]; then
  echo >&2 "ERROR: Mount point '${MNTPATH}' does not exist."
  exit 1
fi
if [ -e "/dev/mapper/${DEVNAME}" ]; then
  echo >&2 "ERROR: The device name '${DEVNAME}' is already in use."
  exit 1
fi

if [ ! -e "${KEYFILE}" ]; then
  echo >&2 "NOTICE: Key file '${KEYFILE}' is missing; using password instead."
  if ! sudo cryptsetup --verbose \
                       --type plain \
                       --cipher "${CIPHER}" \
                       --key-size "${KEY_SIZE}" \
                       --hash "${HASH_ALG}" \
                       --iter-time "${ITER_TIME}" \
                       open "${STORAGE}" "${DEVNAME}"; then
    echo >&2 "ERROR: Failed to unlock container '${STORAGE}'."
    exit 1
  fi
else
  echo >&2 "NOTICE: Using key file '${KEYFILE}'."
  if ! sudo cryptsetup --verbose \
                       --type plain \
                       --key-file "${KEYFILE}" \
                       --cipher "${CIPHER}" \
                       --key-size "${KEY_SIZE}" \
                       --iter-time "${ITER_TIME}" \
                       open "${STORAGE}" "${DEVNAME}"; then
    echo >&2 "ERROR: Failed to unlock container '${STORAGE}'."
    exit 1
  fi
fi

if [ ! -e "/dev/mapper/${DEVNAME}" ]; then
  echo >&2 "ERROR: Device '/dev/mapper/${DEVNAME}' is not available."
  exit 1
fi

if ! sudo chmod 700 "${MNTPATH}"; then
  echo >&2 "ERROR: Failed to set permissions for mount point '${MNTPATH}'."
  exit 1
fi

if ! sudo mount "/dev/mapper/${DEVNAME}" "${MNTPATH}"; then
  echo >&2 "ERROR: Failed to mount '/dev/mapper/${DEVNAME}'."
  exit 1
fi


echo "Mounted '/dev/mapper/${DEVNAME}' -> '${MNTPATH}'."
exit 0
