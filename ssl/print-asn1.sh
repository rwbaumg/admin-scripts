#!/bin/bash
# Dumps the ASN.1 structure of the specified certificate

hash openssl 2>/dev/null || { echo >&2 "You need to install openssl. Aborting." exit 1; }

# Load configuration
if ! source $(dirname $0)/config.sh; then
  echo >&2 "ERROR: Failed to load configuration file."
  exit 1
fi

export OPENSSL_CONF="etc/root-ca.conf"

CERT="$1"
if [ -z "${CERT}" ]; then
  echo "Usage: $0 <cert>"
  exit 1
fi

if [ ! -e "${CERT}" ]; then
  echo >&2 "ERROR: Certificate does not exist."
  exit 1
fi

if ! openssl asn1parse -in "${CERT}"; then
  exit 1
fi

exit 0
