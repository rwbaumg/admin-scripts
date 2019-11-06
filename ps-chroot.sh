#!/bin/bash
# list processes running inside of schroot jails
# this script will enumerate all of the installed
# schroots, and then check the mount point to see
# if it's jailed.

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# the mountpoint used by schroot
# this is used to determine which procs are jailed so it must be correct!
MOUNTPOINTS=("/var/lib/schroot/mount" "/var/chroot")

for chroot in $(schroot -l|awk -F : '{print $2}'); do
  PROCS=""
  for p in $(ps -o pid -A); do
    LINK=$(readlink "/proc/$p/root")
    for mp in "${MOUNTPOINTS[@]}"; do
      if [[ $LINK == "$mp/$chroot"* ]]; then
        PROCS="$PROCS $p"
      fi
    done
  done
  echo "Jailed in \"$chroot\": $PROCS"
done
