#!/bin/bash

if [[ $EUID -ne 0 ]] && [[ "$USER" != "bareos" ]]; then
   echo "This script must have permissions to read the Bareos configuration files." >&2
   exit 1
fi

if ! [ -e /etc/bareos/bareos-fd.d/director/bareos-dir.conf ]; then
  echo >&2 "ERROR: Missing /etc/bareos/bareos-fd.d/director/bareos-dir.conf (is Bareos installed?)"
  exit 1
fi

# get (unquoted) password from config file
FD_PASS=$(grep Password /etc/bareos/bareos-fd.d/director/bareos-dir.conf | awk '{print $3}' | sed -e 's/^"//' -e 's/"$//')

if [ -z "$FD_PASS" ]; then
  echo >&2 "ERROR: Failed to determine client password."
  exit 1
fi

echo >&2 "To add this client to Bareos, run the following command on the server:"
echo >&2
echo "  " echo \"configure add client name=$(hostname) address=$(hostname --fqdn) password=${FD_PASS}\" \| sudo bconsole
echo >&2

exit 0
