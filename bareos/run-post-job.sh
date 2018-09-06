#!/bin/bash
# perform post-job tasks

JOB_ID=$1
CATALOG="BareosCatalog"

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

bconsole <<END_OF_DATA 2>&1 >/dev/null
@output /dev/null
@output
use catalog=${CATALOG}
.bvfs_update jobid=${JOB_ID}
quit
END_OF_DATA

if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed to run post-job commands for job ${JOB_ID}."
  exit 1
fi

exit 0
