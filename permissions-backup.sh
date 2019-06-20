#!/bin/bash
# creates a backup of all file and folder ownership and permissions
# output is stored in the format 'user:group chmod path'

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo >&2 "This script must be run as root."
   exit 1
fi

TODAY=$(date +"%Y-%m-%d")

find / -name '*' -printf '%u:%g %m %p\n' > "permissions-backup-${TODAY}.txt"

exit 0
