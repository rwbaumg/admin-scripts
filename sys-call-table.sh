#!/bin/bash
# display the syscall table

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

cat /boot/System.map-$(uname -r) | grep sys_call_table | cut -d " " -f 1
