#!/bin/bash
# print the full command line of the specified process by pid

PID=$1

if [ -z "$PID" ]; then
  echo >&2 "Must specify a valid process ID (PID) to read the command from."
  exit 1
fi

# check to make sure value is a valid port
re='^[0-9]+$'
if ! [[ $PID =~ $re ]] ; then
  echo >&2 "ERROR: '$PID' is not a valid PID."
  exit 1
fi

# valid PIDs start at one
if [ "$PID" -lt 1 ]; then
  echo >&2 "ERROR: '$PID' is less than 1 and is not a valid PID."
  exit 1
fi

# print the full command line of the specified process
ps --no-headers -up "$PID" |  awk '{ s = ""; for (i = 11; i <= NF; i++) s = s $i " "; print s }'

exit 0
