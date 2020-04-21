#!/bin/bash
# display the syscall table

# check if superuser
if [[ $EUID -ne 0 ]]; then
  echo >&2 "This script must be run as root."
  exit 1
fi

grep sys_call_table "/boot/System.map-$(uname -r)" | cut -d " " -f 1

exit 0
