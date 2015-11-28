#!/bin/bash
# read strings from memory

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

dd if=/dev/mem | cat | strings
