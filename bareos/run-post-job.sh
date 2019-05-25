#!/bin/bash
# perform post-job tasks

JOB_ID=$1
CATALOG="BareosCatalog"

hash bconsole 2>/dev/null || { echo >&2 "You need to install bareos-bconsole. Aborting."; exit 1; }

if [ -z "${JOB_ID}" ]; then
  echo >&2 "ERROR: No job specified."
  exit 1
fi

# validate job number
re='^[0-9]+$'
if ! [[ $JOB_ID =~ $re ]] ; then
  echo >&2 "ERROR: '${JOB_ID}' is not a valid job identifier."
  exit 1
fi

if ! OUTPUT=$(bconsole << END_OF_DATA
@output /dev/null
@output
use catalog=${CATALOG}
.bvfs_update jobid=${JOB_ID}
quit
END_OF_DATA
); then
  echo >&2 "ERROR: Failed to run post-job commands for job ${JOB_ID}."
  if [ -n "${OUTPUT}" ]; then
    echo >&2 "ERROR: Command output: ${OUTPUT}"
  fi
  exit 1
fi

exit 0
