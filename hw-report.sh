#!/bin/bash
# create a report of available hardware

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

lshw -html > hardware.html
