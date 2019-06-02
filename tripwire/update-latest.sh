#!/bin/bash
# TripWire Update Script

REPORT_DIR="/var/lib/tripwire/report"

hash tripwire 2>/dev/null || { echo >&2 "You need to install tripwire. Aborting."; exit 1; }

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# Get the filename of the newest report
REPORT=$(find "$REPORT_DIR" -type f -printf "%T@ %p\n" | sort -k1 -n | tail -n1 | cut -d' ' -f 2-)
if [[ -z "$REPORT" ]]; then
  echo "Fatal: Couldn't find latest report, exiting..." >&2
  exit 1
else
  echo "Updating report: $REPORT"
fi

if ! tripwire --update --twrfile "$REPORT" && tripwire --init; then
  exit 1
fi

exit 0
