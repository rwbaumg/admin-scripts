#!/bin/bash
# a simple cpu benchmark using PI calculation

CPU="${1:-1}";
SCALE="${2:-5000}";

hash bc 2>/dev/null || { echo >&2 "You need to install bc. Aborting."; exit 1; }

echo "Cores: $CPU"; echo "Digit: $SCALE" ;
for i in $(seq 1 "$CPU"); do
  echo "Starting working on CPU $i ..."
  time echo "scale=${SCALE}; 4*a(1)" | bc -l -q | grep -v ^"[0-9]"
done

exit 0
