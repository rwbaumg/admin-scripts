#!/bin/bash
# Configures capabilities for Bareos LTO encryption plugin

hash setcap 2>/dev/null || { echo >&2 "You need to install libcap2-bin. Aborting."; exit 1; }

if [ ! -e "/usr/sbin/bareos-sd" ]; then
  echo >&2 "ERROR: Missing bareos-sd command: /usr/sbin/bareos-sd"
  exit 1
fi
if [ ! -e "/usr/sbin/bscrypto" ]; then
  echo >&2 "ERROR: Missing bscrypto command: /usr/sbin/bscrypto"
  exit 1
fi

setcap cap_sys_rawio=ep /usr/sbin/bareos-sd
setcap cap_sys_rawio=ep /usr/sbin/bscrypto

if ! setcap -v cap_sys_rawio=ep /usr/sbin/bareos-sd; then
  echo >&2 "ERROR: Failed to call setcap for /usr/sbin/bareos-sd"
  exit 1
fi
if ! setcap -v cap_sys_rawio=ep /usr/sbin/bscrypto; then
  echo >&2 "ERROR: Failed to call setcap for /usr/sbin/bscrypto"
  exit 1
fi

exit 0
