#!/bin/bash
# triggers a live reload of suricata rules

hash suricata 2>/dev/null || { echo >&2 "You need to install suricata. Aborting."; exit 1; }

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# make sure suricata is running
SURICATA_PID=$(pidof -s "suricata")
if [[ -z "$SURICATA_PID" ]]; then
  echo >&2 "ERROR: Suricata doesn't appear to be running."
  exit 1
fi

for x in `pidof - "suricata"`; do
  # send live reload signal (USR2)
  echo "Sending live reload signal to suricata pid $x ..."
  kill -USR2 $x
done

exit 0
