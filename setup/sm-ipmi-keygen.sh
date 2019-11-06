#!/bin/bash
# Supermicro IPMI key generator
# See https://peterkleissner.com/2018/05/27/reverse-engineering-supermicro-ipmi/

echo "Supermicro IPMI/OOB management key generator"

# TODO: Validate input MAC

if [ -z "$1" ]; then
  echo "Usage: $0 <ipmi_mac>" >&2
  exit 1
fi

MAC=$(echo "${1}" | awk '{ print toupper($0) }')
MAC=${MAC//[^0-9A-F]/}

if ! key=$(echo -n "${MAC}" \
            | xxd -r -p \
            | openssl dgst -sha1 -mac HMAC -macopt hexkey:8544E3B47ECA58F9583043F8 \
            | awk '{print $2}' \
            | cut -c 1-24 \
            | sed 's/.\{4\}/&\-/g;s/\-$//'); then
  echo "ERROR: Failed to generate IPMI key." >&2
  exit 1
fi

echo "IPMI MAC address : ${MAC}"
echo "IPMI license key : ${key}"

exit 0
