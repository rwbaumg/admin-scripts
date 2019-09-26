#!/bin/bash
# Test available memory bus bandwidth using netperf

hash netperf 2>/dev/null || { echo >&2 "You need to install netperf. Aborting."; exit 1; }

#if ! source "$(dirname "$0")/../helpers/fs.sh"; then
#  echo >&2 "ERROR: Failed to load $(dirname "$0")/../helpers/fs.sh"
#  exit 1
#fi

if ! OUTPUT=$(netperf -T0,0 -C -c -P1); then
  exit 1
fi

RESULT=$(echo "${OUTPUT}" | tail -n1)
SPEED=$(echo "${RESULT}" | awk '{ print $5 }')

echo "${OUTPUT}"
echo

# Total bandwidth - 10^6bits/s (or 1 Mb/s)
# MBPS=$(awk "BEGIN {print (${SPEED}/8)}")
# echo "Total bandwidth: ${MBPS} MB/s"

# Convert 10^6bits/s -> bps
BPS=$(awk "BEGIN {print (${SPEED}*125000)}")
# echo "Total bandwidth: $(getSizeString "${BPS}")/s"

# Gb/s = n/125000000
# GB/s = n/1250000000

GBPS=$(awk "BEGIN {print (${BPS}/125000000)}")
echo "Total bandwidth: ${GBPS} Gb/s"

exit 0
