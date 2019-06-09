#!/bin/bash
# clears lastlog entries
# all users will appear to have never logged in
# warning: this script is noisy and will raise flags on monitored systems

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

true > /var/log/lastlog

exit 0
