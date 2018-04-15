#!/bin/bash
# display a certificate

if [[ -z "$1" ]]; then
  echo >&2 "Usage: $0 <file>"
  exit 1
fi
if [ ! -f "$1" ]; then
  echo >&2 "Certificate not found: $1"
  exit 1
fi

FILE=$(readlink -m "$1")

echo "File: $FILE"
openssl x509 -in $FILE -noout -text

exit 0
