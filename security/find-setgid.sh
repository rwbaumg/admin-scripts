#!/bin/bash
# find all setgid binaries

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

find / -xdev \( -perm -2000 \) -type f -print0 | xargs -0 ls -l
