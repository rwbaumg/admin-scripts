#!/bin/bash
# Show some basic tape information

DRIVE="/dev/nst0"

hash tapeinfo 2>/dev/null || { echo >&2 "You need to install mtx. Aborting."; exit 1; }
hash bscrypto 2>/dev/null || { echo >&2 "You need to install bareos-storage-tape. Aborting."; exit 1; }

tapeinfo -f ${DRIVE} && echo && bscrypto -e ${DRIVE}

exit 0
