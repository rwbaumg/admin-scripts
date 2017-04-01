#!/bin/bash
# Generate a new MAC address given a hostname

# note: first octet must be event according to spec
FIRST_OCTET="88"
MACADDR=$(echo "$1"|sha1sum|sed "s/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/${FIRST_OCTET}:\1:\2:\3:\4:\5/")
echo $MACADDR
