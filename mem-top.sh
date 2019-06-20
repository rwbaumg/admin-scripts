#!/bin/bash
# print top processes by memory usage

OUTPUT_CN=10
PS_OUTPUT="user,pid,pcpu,pmem,comm"
PS_MEM_CN=4

# check if an argument was provided
if [ $# -gt 0 ]; then
  if [[ "$*" =~ ^-?[0-9]+$ ]]; then
    OUTPUT_CN=$*
  else
    echo >&2 "ERROR: Argument must be a valid number."
    exit 1
  fi
fi

# print header
ps -axo ${PS_OUTPUT} | head -n1

# print output
if ! OUTPUT=$(ps --no-headers -axo ${PS_OUTPUT} | sort -rnk +${PS_MEM_CN}); then
  exit 1
fi

echo "${OUTPUT}" | head -n"${OUTPUT_CN}"
exit 0
