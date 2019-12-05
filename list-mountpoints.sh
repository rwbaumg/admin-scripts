#!/bin/bash

if ! info=$(sudo mount -v | grep "^/" | awk '{print "Partition identifier: " $1  "\n Mountpoint: "  $3 "\n"}'); then
  echo >&2 "ERROR: Failed to get mountpoint info."
  exit 1
fi

#printf "System mountpoints: \n"
#printf "=================== \n"

printf "%s\n" "$info"

exit 0
