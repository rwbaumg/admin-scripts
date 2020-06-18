#!/bin/bash
# Read system interrupt(s).

IRQ_REQ="$1"

if ! OUTPUT=$(cat /proc/interrupts | tail -n+2 | awk '{ printf "IRQ %s %s %s %s\n", $1, $(NF - 2), $(NF - 1), $(NF) }'); then
  echo >&2 "ERROR: Failed to read interrupts."
  exit 1
fi

if [ ! -z "${IRQ_REQ}" ]; then
  if ! echo "${OUTPUT}" | grep -P "^(IRQ(\s)?)?${IRQ_REQ}\:"; then
    echo "ERROR: Could not find interrupt '${IRQ_REQ}'."
  fi
else
  echo "${OUTPUT}"
fi

exit 0
