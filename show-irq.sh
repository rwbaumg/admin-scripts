#!/bin/bash
# Read system interrupt(s).

IRQ_REQ="$1"

if ! OUTPUT=$(cat /proc/interrupts | tail -n+2 | awk '{ printf "IRQ %s %s %s %s\n", $1, $90, $91, $92 }'); then
  echo >&2 "ERROR: Failed to read interrupts."
  exit 1
fi

if [ ! -z "${IRQ_REQ}" ]; then
  echo "${OUTPUT}" | grep -P "^(IRQ(\s)?)?${IRQ_REQ}\:"
else
  echo "${OUTPUT}"
fi

exit 0
