#!/bin/bash

hash cryptsetup 2>/dev/null || { echo >&2 "You need to install cryptsetup-bin. Aborting."; exit 1; }

# Load configuration
CONFIG=`dirname $0`/config.sh
if ! [ -e "${CONFIG}" ]; then
  echo >&2 "ERROR: Missing configuration file '${CONFIG}'."
  exit 1
fi
source ${CONFIG}

if [ -e "/dev/mapper/${DEVNAME}" ]; then
  echo >&2 "ERROR: The device name '${DEVNAME}' is already in use."
  exit 1
fi
if [ -e "${STORAGE}" ]; then
  echo >&2 "ERROR: The container '${STORAGE}' already exists."
  exit 1
fi
if [ ! -e "${DEV_RND}" ]; then
  echo >&2 "ERROR: Entropy source '${DEV_RND}' does not exist."
  exit 1
fi

# create 10gb storage file
echo "Writing ${SIZE_MB}MB from '${DEV_RND}' -> '${STORAGE}'..."
dd if=${DEV_RND} of=${STORAGE} bs=1M count=${SIZE_MB}
if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed creating container '${STORAGE}'."
  exit 1
fi
if [ ! -e "${STORAGE}" ]; then
  echo >&2 "ERROR: Storage file '${STORAGE}' is missing."
  exit 1
fi

if [ ! -e "${KEYFILE}" ]; then
  echo >&2 "NOTICE: Key file '${KEYFILE}' is missing; using password instead."
  sudo cryptsetup --verbose \
                  --type plain \
                  --verify-passphrase \
                  --cipher ${CIPHER} \
                  --key-size ${KEY_SIZE} \
                  --hash ${HASH_ALG} \
                  --iter-time ${ITER_TIME} \
                  open "${STORAGE}" ${DEVNAME}
  if ! [ $? -eq 0 ]; then
    echo >&2 "ERROR: Failed to unlock container '${STORAGE}'."
    exit 1
  fi
else
  echo >&2 "NOTICE: Using key file '${KEYFILE}'."
  sudo cryptsetup --verbose \
                  --type plain \
                  --key-file ${KEYFILE} \
                  --cipher ${CIPHER} \
                  --key-size ${KEY_SIZE} \
                  --iter-time ${ITER_TIME} \
                  open "${STORAGE}" ${DEVNAME}
  if ! [ $? -eq 0 ]; then
    echo >&2 "ERROR: Failed to unlock container '${STORAGE}'."
    exit 1
  fi
fi

if [ ! -e "/dev/mapper/${DEVNAME}" ]; then
  echo >&2 "ERROR: Device '/dev/mapper/${DEVNAME}' is not available."
  exit 1
fi

echo "Formatting filesystem to ext4..."
sudo mkfs.ext4 /dev/mapper/${DEVNAME}
if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed to format '/dev/mapper/${DEVNAME}'."
  exit 1
fi

echo "Mounting new filesystem..."
sudo chmod 700 "${MNTPATH}"
if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed to set permissions for mount point '${MNTPATH}'."
  exit 1
fi

sudo mount /dev/mapper/${DEVNAME} "${MNTPATH}"
if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed to mount '/dev/mapper/${DEVNAME}'."
  exit 1
fi

echo "Mounted '/dev/mapper/${DEVNAME}' -> '${MNTPATH}'."
exit 0
