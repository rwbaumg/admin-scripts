#!/bin/bash
# Generate a new MAC address given a hostname

MACADDR=$(echo "$1"|sha1sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
echo $MACADDR
