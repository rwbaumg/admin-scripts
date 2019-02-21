#!/bin/bash
# Configures capabilities for Bareos LTO encryption plugin

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
