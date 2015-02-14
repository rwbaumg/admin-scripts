#!/bin/bash
# list processes running inside of schroot jails
# this script will enumerate all of the installed 
# schroots, and then check the mount point to see
# if it's jailed.

# the mountpoint used by schroot
# this is used to determine which procs are jailed so it must be correct!
MOUNTPOINT="/var/lib/schroot/mount"

for chroot in `schroot -l|awk -F : '{print $2}'`; do
  PROCS=""
  for p in `ps -o pid -A`; do
    LINK=$(readlink /proc/$p/root)
    if [[ $LINK == "$MOUNTPOINT/$chroot"* ]]; then
      PROCS="$PROCS $p"
    fi
  done
  echo "Jailed in \"$chroot\": $PROCS"
done
