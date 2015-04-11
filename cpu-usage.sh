#!/bin/bash
# gets current (total) cpu usage
# rwb < rwb[at]0x19e.net >

MPSTAT_BIN=$(which mpstat)
TOP_BIN=$(which top)

if [[ -z "$MPSTAT_BIN" ]]; then
  # echo "Using '$TOP_BIN' for calculating CPU usage..."

  $TOP_BIN -bn1 | grep "Cpu(s)" | \
             sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | \
             awk '{print 100 - $1"%"}'
else
  # echo "Using '$MPSTAT_BIN' for calculating CPU usage..."
  LANG=c $MPSTAT_BIN | awk '$12 ~ /[0-9.]+/ { print 100 - $12"%" }'
fi
