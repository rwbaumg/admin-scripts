#!/bin/bash
# create a report of available hardware
# Only the full path to the report is sent to stdout
# For example, to store it in a variable:
#  `REPORT_PATH=$(sudo ./hw-report.sh 2>/dev/null)`

# check if superuser
#if [[ $EUID -ne 0 ]]; then
#   echo "This script must be run as root" >&2
#   exit 1
#fi

OUTPUT="hardware.html"

if ! RAW=$(sudo lshw -html); then
  echo >&2 "ERROR: Failed to generate hardware report."
  exit 1
fi

echo "${RAW}" > "${OUTPUT}"

echo >&2 "Saved hardware report to $(basename ${OUTPUT})"
readlink -f "${OUTPUT}"
exit 0
