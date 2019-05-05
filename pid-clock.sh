#!/bin/bash
# Watches a running process until it completes

# Here's the one-liner this script is created from:
# PID=0; SP='\|/-'; i=1; while `ps -p $PID > /dev/null`; do PROC_TIME=$(ps -p $PID -o etime= | awk '{ print $1 }'); printf "\n"; printf "\b\r[${SP:i++%${#SP}:1}] PID $PID is running ($PROC_TIME)"; sleep 1; done;

# check if an argument was provided
if [ $# -gt 0 ]; then
  if [[ "$@" =~ ^-?[0-9]+$ ]]; then
    PID=$@
  else
    echo >&2 "ERROR: Argument must be a valid number."
    exit 1
  fi
fi

# check if pid is running
if ! $(ps -p $PID > /dev/null); then
  echo "The specified PID is not valid."
  exit 1
fi

i=1;
SP='\|/-';
while $(ps -p $PID > /dev/null); do
	PROC_TIME=$(ps -p $PID -o etime= | awk '{ print $1 }');
	printf "\b\r[${SP:i++%${#SP}:1}] PID $PID is running ($PROC_TIME)";
	sleep 1;
done;

printf "\b\rPID $PID has exited after $PROC_TIME\n"

exit 0
