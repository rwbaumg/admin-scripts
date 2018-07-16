#!/bin/bash
# clean PEM certificates

# note: use either '$*' or '$@' to process all input
for f in $*; do
  echo "Cleaning PEM file: $f"
  openssl x509 -in "$f" -outform pem -out "$f"
done

exit 0
