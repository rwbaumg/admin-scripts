#!/bin/bash
#
# Tests OpenSSL OID recognition and support.
#
# If OpenSSL returns a String identifier for the supplied OID, then
# that OID was compiled into the version of OpenSSL along with an
# ASN.1 definition for it.
#
hash openssl 2>/dev/null || { echo >&2 "You need to install openssl. Aborting."; exit 1; }

OID="$1"
if [ -z "${OID}" ]; then
  echo "Usage: $0 <oid> [config]"
  exit 1
fi

if [ -n "$2" ]; then
  if [ -e "$2" ]; then
    export OPENSSL_CONF="$2"
    echo "Using configuration file ${OPENSSL_CONF}"
  else
    echo "ERROR: Configuration file '${OPENSSL_CONF}' does not exist."
    exit 1
  fi
fi

if ! OUTPUT=$(openssl asn1parse -genstr OID:"${OID}"); then
  echo >&2 "ERROR: Failed to parse Object identifier '${OID}'."
  exit 1
fi

echo "${OUTPUT}"

exit 0
