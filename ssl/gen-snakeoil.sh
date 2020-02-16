#!/bin/bash
# Generate a new 'snakeoil' self-signed certificate for testing

hash make-ssl-cert 2>/dev/null || { echo >&2 "You need to install ssl-cert. Aborting."; exit 1; }

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo >&2 "ERROR: This script must be run as root."
   exit 1
fi

echo "Installing new self-signed snakeoil certificate ..."
if ! make-ssl-cert generate-default-snakeoil --force-overwrite; then
  echo >&2 "Failed."
  exit 1
fi

echo "Finished."
exit 0
