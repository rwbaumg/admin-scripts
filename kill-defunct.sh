#!/bin/bash
# script to kil defunct processes

# NOTE: Need to test the following command against current implementation:
#  ps afx | grep defunct -B 1 | grep -Eo "[0-9]{3,}" | xargs kill -9

# get a list of unique zombie pids
ZOMBIE_PIDS=$(ps --no-headers -A -ostat,ppid | awk '/[zZ]/{print $2}' | sort -n | uniq)

if [ -z "$ZOMBIE_PIDS" ]; then
  echo "No zombie processes detected."
  exit 1
fi

echo "Sending kill signal to zombie PIDs..."
echo "PIDs: $ZOMBIE_PIDS"

kill "$ZOMBIE_PIDS"

exit 0
