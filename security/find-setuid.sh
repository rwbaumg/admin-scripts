#!/bin/bash
# find all setuid binaries

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

find / \( -perm -4000 -o -perm -2000 \) -type f -exec ls -la {} \;

exit 0
