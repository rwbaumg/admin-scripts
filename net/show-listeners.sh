#!/bin/bash
# list all active listeners
# rwb[at]0x19e[dot]net

hash awk 2>/dev/null || { echo >&2 "You need to install awk. Aborting."; exit 1; }

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# get all running listeners
LISTENERS="$(lsof -Pan -i tcp -i udp | grep -v PID | awk '{print $2,$9}')"

# print header
printf "%-40s %-10s %s\n" "CONNECTION" "PID" "COMMAND"
printf "=%.0s" {1..100}
printf "\n"

# loop through each entry and print out relavent info
IFS=$'\n'; for line in $LISTENERS; do
  pid=$(echo $line | awk '{print $1}')
  con=$(echo $line | awk '{print $2}')
  cmd=$(ps -p $pid -o args | grep -v COMMAND)
  OUT=$(printf "%-40s %-10s %s\n" $con $pid $cmd | sed '/^\s*$/d')
  if [ -n $OUT ]; then
    echo $OUT
  fi
done
