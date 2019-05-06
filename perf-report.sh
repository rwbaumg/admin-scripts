#!/bin/bash
# Records performance data and displays a report

REC_SECONDS=10

source $(dirname $0)/helpers/spinner.sh

OWNS_DATA=0
if [ ! -e "./perf.data" ]; then
  OWNS_DATA=1
fi

start_spinner "Recording performance data for ${REC_SECONDS} seconds ..."
if ! $(sudo perf record -g -a sleep ${REC_SECONDS} > /dev/null 2>&1); then
  stop_spinner 1
  echo >&2 "ERROR: Failed to record performance data."
  exit 1
fi
stop_spinner 0

echo "Displaying report..."
if ! sudo perf report; then
  echo >&2 "ERROR: Failed to display report."
  exit 1
fi

# Delete perf.data file
if [ ${OWNS_DATA} -eq 1 ]; then
  sudo rm -v ./perf.data
fi

echo "Finished."

exit 0
