#!/bin/bash
# Dump entries from local arpwatch database(s)

ARP_DB="/var/lib/arpwatch/*.dat"

hash arpwatch 2>/dev/null || { echo >&2 "You need to install arpwatch. Aborting."; exit 1; }

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo >&2 "ERROR: This script must be run as root."
   exit 1
fi

# check for arpwatch database
if ! ls ${ARP_DB} 1> /dev/null 2>&1; then
  echo >&2 "ERROR: Could not find arpwatch database(s) '${ARP_DB}'."
  exit 1
fi

# Alternate method of checking for database file(s)
#for f in ${ARP_DB}; do
#    if [ ! -e "$f" ]; then
#      echo >&2 "ERROR: Could not find arpwatch database(s) '${ARP_DB}'."
#      exit 1
#    fi
#    break
#done

# Get list of IP addresses in arpwatch database
cat ${ARP_DB} | awk -F'\t' '{printf "%-18s %-20s %s\n", $2, $1, $4}' | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 | uniq

exit $?
