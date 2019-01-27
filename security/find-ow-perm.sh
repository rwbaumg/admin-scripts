#!/bin/bash
# searches for files/folders with o+w permission bit

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

find / -xdev \( -perm o+w \) -type f -print0 2>&- | xargs -0 ls -l

exit 0
