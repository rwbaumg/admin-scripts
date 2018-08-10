#!/bin/bash
# 0x19e Networks
#
# Clean the specified tape by writing an EOF to the start.
#
# Robert W. Baumgartner <rwb@0x19e.net>

if [[ -z "$1" ]]; then
  echo "Usage: $0 <slot-number>"
  exit 1
fi

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

SLOT_NUMBER=$1
DRIVE_INDEX=0
AUTOCHANGER=/dev/sg1
TAPE_DRIVE=/dev/st0
CHANGER_SCRIPT="/usr/lib/bareos/scripts/mtx-changer"

# check slot number
re='^[1-9]+$'
if ! [[ $1 =~ $re ]] ; then
  echo >&2 "ERROR: Argument '${SLOT_NUMBER}' is not a valid slot number."
  exit 1
fi

# check if superuser
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" >&2
  exit 1
fi

if [ ! -e "${CHANGER_SCRIPT}" ]; then
  echo >&2 "ERROR: Changer script '${CHANGER_SCRIPT}' does not exist."
  exit 1
fi

if [ ${SLOT_NUMBER} -le 0 ]; then
  echo >&2 "ERROR: Invalid slot number: ${SLOT_NUMBER}"
  exit 1
fi

echo "Processing cleanup request for tape ${SLOT_NUMBER} in autochanger ${AUTOCHANGER} ..."

STATUS_OUTPUT=$(mtx -f ${AUTOCHANGER} status)
SLOT_STATUS=$(echo ${STATUS_OUTPUT} | grep "Storage Element ${SLOT_NUMBER}:" | awk -F: '{print $2}')
DRIVE_STATUS=$(echo ${STATUS_OUTPUT} | grep "Data Transfer Element ${DRIVE_INDEX}:" | awk -F: '{print $2}')

# check the drive to make sure it is empty
if [ "${DRIVE_STATUS}" != "Empty" ]; then
  # get the element number of the loaded tape
  # TAPE_IN_DRIVE=$(echo $DRIVE_STATUS | grep -Po '(?<=\(Storage\sElement\s)\d(?=\sLoaded\))')
  TAPE_IN_DRIVE=$(${CHANGER_SCRIPT} ${AUTOCHANGER} loaded 0 ${TAPE_DRIVE} ${DRIVE_INDEX})

  echo "Found tape ${TAPE_IN_DRIVE} loaded in drive ${DRIVE_INDEX} (${TAPE_DRIVE})"

  if [ "${TAPE_IN_DRIVE}" != "${SLOT_NUMBER}" ]; then
    # unload the current tape
    echo "Unloading tape ${TAPE_IN_DRIVE} ..."
    ${CHANGER_SCRIPT} ${AUTOCHANGER} unload ${TAPE_IN_DRIVE} ${TAPE_DRIVE} ${DRIVE_INDEX}
    if ! [ $? -eq 0 ]; then
      echo >&2 "ERROR: Failed to unload tape ${TAPE_IN_DRIVE} from drive ${DRIVE_INDEX} (${TAPE_DRIVE})."
      exit 1
    fi
  fi
fi

TAPE_IN_DRIVE=$(${CHANGER_SCRIPT} ${AUTOCHANGER} loaded 0 ${TAPE_DRIVE} ${DRIVE_INDEX})
if [ "${TAPE_IN_DRIVE}" != "${SLOT_NUMBER}" ]; then
  echo "Loading tape ${SLOT_NUMBER} to drive ${DRIVE_INDEX} (${TAPE_DRIVE}) ..."
  ${CHANGER_SCRIPT} ${AUTOCHANGER} load ${SLOT_NUMBER} ${TAPE_DRIVE} ${DRIVE_INDEX}
  if ! [ $? -eq 0 ]; then
    echo >&2 "ERROR: Failed to load tape ${SLOT_NUMBER} to drive ${DRIVE_INDEX} (${TAPE_DRIVE})."
    exit 1
  fi
fi

echo "Rewinding tape..."
mt -f ${TAPE_DRIVE} rewind

echo "Writing EOF to start of tape..."
mt -f ${TAPE_DRIVE} weof

echo "Status after write:"
mt -f ${TAPE_DRIVE} status

echo "Finished."
exit 0
