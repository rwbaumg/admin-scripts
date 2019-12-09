#!/bin/bash
# Lists partitions on the current system
#
# NOTE: To remount a given filesystem, for example to enable RW:
#            sudo mount -o remount,rw /partition/identifier /mount/point

if ! info=$(sudo mount -v | grep "^/" | awk '{print "Partition identifier: " $1  "\n Mountpoint: "  $3 "\n"}'); then
  echo >&2 "ERROR: Failed to get mountpoint info."
  exit 1
fi

#printf "System mountpoints: \n"
#printf "=================== \n"

printf "%s\n" "$info"

exit 0
