#!/bin/bash
CHROOT_ROOT="/srv/chroot/"
PROCS=""
for chroot in `schroot -l|awk -F : '{print $2}'`; do
  for p in `ps -o pid -A`; do
    if [ "`readlink /proc/$p/root`" = "$CHROOT_ROOT/$chroot" ]; then
      PROCS="$PROCS $p"
    fi
  done
  echo "Jailed in \"$chroot\": $PROCS"
done
