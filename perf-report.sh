#!/bin/bash
# Records performance data and displays a report

REC_SECONDS=4
USE_SPINNER=0

hash perf 2>/dev/null || { echo >&2 "The perf command is missing; you need to install linux-tools-common and/or linux-tools-generic. Aborting."; exit 1; }
hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }

if [[ ${USE_SPINNER} -eq 1 ]] && [ ! -e "$(dirname $0)/helpers/spinner.sh" ]; then
  echo >&2 "WARNING: Cannot find spinner source file: ./helpers/spinner.sh"
  USE_SPINNER=0
fi

if [[ ${USE_SPINNER} -eq 1 ]]; then
  if ! source $(dirname $0)/helpers/spinner.sh; then
    echo >&2 "WARNING: Failed to include spinner source file: ./helpers/spinner.sh"
    USE_SPINNER=0
  fi
fi

if [[ $EUID -ne 0 ]]; then
  echo >&2 "User is not root; checking sudo privileges for current user $USER ..."
  if ! sudo echo "" > /dev/null 2>&1; then
    echo >&2 "ERROR: User $USER does not have or failed to authenticate for sudo privileges."
    exit 1
  fi
fi

OWNS_DATA=0
if [ ! -e "./perf.data" ]; then
  OWNS_DATA=1
fi

if [[ ${USE_SPINNER} -eq 1 ]]; then
  start_spinner "Recording performance data for ${REC_SECONDS} seconds ..."
else
  echo -n       "Recording performance data for ${REC_SECONDS} seconds ... "
fi

if ! $(sudo perf record -g -a sleep ${REC_SECONDS} > /dev/null 2>&1); then
  if [[ ${USE_SPINNER} -eq 1 ]]; then stop_spinner 1; else echo "done."; fi
  echo >&2 "ERROR: Failed to record performance data."
  exit 1
fi
if [[ ${USE_SPINNER} -eq 1 ]]; then stop_spinner 0; else echo "done."; fi

echo -n "Displaying report... "
if ! sudo perf report; then
  echo "error!"
  echo >&2 "ERROR: Failed to display report."
  exit 1
fi

# Delete perf.data file
if [[ ${OWNS_DATA} -eq 1 ]]; then
  if [ -e "./perf.data" ]; then
    sudo rm ./perf.data
  fi
fi

echo "finished."

exit 0
