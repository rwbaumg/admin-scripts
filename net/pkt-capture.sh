#!/bin/bash
# invokes tcpdump on the specified interface
# rwb[at]0x19e[dot]net

hash tcpdump 2>/dev/null || { echo >&2 "You need to install tcpdump. Aborting."; exit 1; }

OPTS="-nnXSs 1514"

if [[ -z "$1" ]]; then
  echo "Usage: $0 <iface> [file]"
  exit 1
fi

if [[ -z "$2" ]]; then
  OUTPUT="${1}-$(date '+%Y%m%d%H%M%S').pcap"
else
  OUTPUT="$2"
fi

echo "Capturing $1 to '$OUTPUT' ..."
tcpdump $OPTS -w "$OUTPUT" -i $1
