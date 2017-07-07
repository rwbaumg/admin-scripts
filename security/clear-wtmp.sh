#!/bin/bash
# clears wtmp and btmp logs
# this clears all entries presented by the last/lastb commands
# warning: this script is noisy and will raise flags on secured systems

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

> /var/log/wtmp
> /var/log/btmp

