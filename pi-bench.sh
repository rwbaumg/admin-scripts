#!/bin/bash
# a simple cpu benchmark using PI calculation

CPU="${1:-1}";
SCALE="${2:-5000}";

echo "Cores: $CPU"; echo "Digit: $SCALE" ;
for LOOP in $(seq 1 $CPU); do
  time echo "scale=${SCALE}; 4*a(1)" | bc -l -q | grep -v ^"[0-9]"
done
