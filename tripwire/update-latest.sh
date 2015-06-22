#!/bin/bash
# TripWire Update Script

REPORT_DIR="/var/lib/tripwire/report"

hash tripwire 2>/dev/null || { echo >&2 "You need to install tripwire. Aborting."; exit 1; }
hash gawk 2>/dev/null || { echo >&2 "You need to install gawk. Aborting."; exit 1; }
hash sed 2>/dev/null || { echo >&2 "You need to install sed. Aborting."; exit 1; }

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Get the filename of the newest report
REPORT=$(ls -lt "$REPORT_DIR" | sed -n 2p | gawk '{print $9}')
if [[ -z "$REPORT" ]]; then
  echo "Fatal: Couldn't find latest report, exiting..."
  exit 1
else
  echo "Updating report: $REPORT_DIR/$REPORT"
fi

tripwire --update --twrfile "$REPORT_DIR/$REPORT" && tripwire --init

exit 0
