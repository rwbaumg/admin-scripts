#!/bin/bash
# list all active listeners
# rwb[at]0x19e[dot]net

if [ -z "${NO_HEADER}" ]; then
  NO_HEADER=1
fi

hash awk 2>/dev/null || { echo >&2 "You need to install awk. Aborting."; exit 1; }

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

function get_lsof_output()
{
  # get all running listeners
  listeners="$(lsof -Pan -i tcp -i udp | grep LISTEN | awk '{print $2,$9}')"
  if [ -z "${listeners}" ]; then
    return 1
  fi

  # loop through each entry and print out relavent info
  IFS=$'\n'; for line in $listeners; do
    pid=$(echo "$line" | awk '{print $1}')
    con=$(echo "$line" | awk '{print $2}')
    cmd=$(ps -p "$pid" -o args --no-headers)
    out=$(printf "%-30s %-10s %s\n" "$con" "$pid" "$cmd" | sed '/^\s*$/d')
    if [ -n "$out" ]; then
      echo "$out"
    fi
  done

  return 0
}

OUTPUT=$(get_lsof_output)

# print header
if [ "${NO_HEADER}" != 1 ]; then
  printf "%-30s %-10s %s\n" "CONNECTION" "PID" "COMMAND"
  # printf "=%.0s" {1..90}; printf "\n"
fi

echo "${OUTPUT}" | LC_ALL=C sort -t: -k2n | uniq

exit 0
