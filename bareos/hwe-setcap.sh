#!/bin/bash
# Configures capabilities for Bareos LTO encryption plugin

hash /sbin/setcap 2>/dev/null || { echo >&2 "You need to install libcap2-bin. Aborting."; exit 1; }

if [ ! -e "/usr/sbin/bareos-sd" ]; then
  echo >&2 "ERROR: Missing bareos-sd command: /usr/sbin/bareos-sd"
  exit 1
fi
if [ ! -e "/usr/sbin/bscrypto" ]; then
  echo >&2 "ERROR: Missing bscrypto command: /usr/sbin/bscrypto"
  exit 1
fi

failed=0
if ! /sbin/setcap -v cap_sys_rawio=ep /usr/sbin/bareos-sd; then
  echo >&2 "ERROR: Failed to call /sbin/setcap for /usr/sbin/bareos-sd"
  failed=1
fi
if ! /sbin/setcap -v cap_sys_rawio=ep /usr/sbin/bscrypto; then
  echo >&2 "ERROR: Failed to call /sbin/setcap for /usr/sbin/bscrypto"
  failed=1
fi

exit $failed
