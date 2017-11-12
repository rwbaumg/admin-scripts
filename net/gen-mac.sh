#!/bin/bash
# Generate a new MAC address given a hostname

# note: first octet must be event according to spec
# the Xensource id is 00:16:3e
# the x19e id is 30:16:c6
# FIRST_OCTET="88"
# MFG_ID="00:16:3e"
MFG_ID="30:16:c6"
SEED_VALUE="$1"
if [[ -z "$SEED_VALUE" ]]; then
  SEED_VALUE=$(uuidgen)
fi
if [[ ! -z "$FIRST_OCTET" ]]; then
  MACADDR=$(echo "$SEED_VALUE"|sha1sum|sed "s/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/${FIRST_OCTET}:\1:\2:\3:\4:\5/")
else
  MACADDR=$(echo "$SEED_VALUE"|sha1sum|sed "s/^\(..\)\(..\)\(..\).*$/${MFG_ID}:\1:\2:\3/")
fi
echo $MACADDR
