#!/bin/bash
# downloads the IANA ports list

hash wget 2>/dev/null || { echo >&2 "You need to install wget. Aborting."; exit 1; }

DOWNLOAD_URL=http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv
# DOWNLOAD_URL=http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.txt

if ! wget "$DOWNLOAD_URL"; then
  exit 1
fi

exit 0
