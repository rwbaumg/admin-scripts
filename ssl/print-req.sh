#!/bin/bash
# Display the contents of a Certificate Signing Request (CSR)

hash openssl 2>/dev/null || { echo >&2 "You need to install openssl. Aborting."; exit 1; }

if [ -z "$1" ]; then
  echo >&2 "Usage: $0 <csr>"
  exit 1
fi

if ( [ ! -e "$1"  ] | [ ! -s "$1" ] ); then
  echo >&2 "ERROR: The specified CSR '${1}' does not exist."
  exit 1
fi

CSR_PATH="$1"
NAMEOPT="dump_nostr,utf8,multiline,show_type"

# Print the CSR
if ! openssl req -noout -text -nameopt ${NAMEOPT} -in "$CSR_PATH"; then
  exit 1
fi

exit 0
