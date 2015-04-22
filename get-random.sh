#!/bin/bash
#

TMP_FILE="/tmp/random_data"

echo "Generating random data..."
dd if=/dev/urandom bs=1 count=256 > /tmp/random_data
RANDOM_HASH=$(sha512sum -b /tmp/random_data | awk '{ print $1 }')
rm $TMP_FILE

echo
echo "Random hash:"
echo
echo $RANDOM_HASH
echo
