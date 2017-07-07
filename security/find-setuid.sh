#!/bin/bash
# find all setuid binaries

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

find / -xdev \( -perm -4000 \) -type f -print0 | xargs -0 ls -l
