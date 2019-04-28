#!/bin/bash
# Process context switching

hash pidstat 2>/dev/null || { echo >&2 "You need to install sysstat. Aborting."; exit 1; }
hash grep 2>/dev/null || { echo >&2 "You need to install grep. Aborting."; exit 1; }
hash awk 2>/dev/null || { echo >&2 "You need to install gawk. Aborting."; exit 1; }

pidstat -w 2 1 | grep Average | grep -v pidstat \
  | sort -r -n -k4 \
  | head -n 20 \
  | awk '{ if ($3 != "PID") printf("PID:%-8s%-12scswch/s\t%-12snvcswch/s\t%s\n", $3, $4, $5, $6) }'

exit $?
