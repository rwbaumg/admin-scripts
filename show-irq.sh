#!/bin/bash
# Read system interrupt(s).

IRQ_REQ="$1"

if ! RAW_OUTPUT=$(grep -vP '^(\s+)?(ERR|MIS)' /proc/interrupts | tail -n+2 | awk '{printf "%s|", $1; for(j=(NF-2);j<=NF;j++){if($j~/^[A-Za-z]/){printf "%s ", $j} }; if($j=NF){printf "\n";} }' && grep -P '^(\s+)?(ERR|MIS)' /proc/interrupts | awk '{printf "%s|%s\n", $1, $2}'); then
  echo >&2 "ERROR: Failed to read interrupts."
  exit 1
fi
if ! OUTPUT=$(echo "${RAW_OUTPUT}" | awk -F'|' '{ printf "IRQ %s %s\n", $1, $2 }'); then
  echo >&2 "ERROR: Failed to parse interrupts."
  exit 1
fi

if [ ! -z "${IRQ_REQ}" ]; then
  if ! echo "${OUTPUT}" | grep -P "^(IRQ(\s+)?)?${IRQ_REQ}(\s+)?\:"; then
    echo "ERROR: Could not find interrupt '${IRQ_REQ}'."
  fi
else
  echo "${OUTPUT}"
fi

exit 0
