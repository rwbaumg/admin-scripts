#!/bin/bash
# invokes tcpdump on the specified interface
# rwb[at]0x19e[dot]net

hash tcpdump 2>/dev/null || { echo >&2 "You need to install tcpdump. Aborting."; exit 1; }

# Specify capture options
# -i  : Specify the interface(s) to capture from, eg. -i eth0
# -e  : Get ethernet header as well
# -n  : Do not resolve hostnames
# -nn : Do not resolve hostnames OR ports
# -s0 : Snap length - 0=unlimited
# -S  : Print absolute sequence numbers
# -X  : Include both hex AND ascii output
# -XX : Same as -X but includes ethernet header
# -v  : Increase packet detail - can be -v, -vv or -vvv
# -w  : Write output to file - eg, -w file.pcap
#
# OPTS="-nnXSs 1514"
# OPTS="-nnvvvXSs 1514"
OPTS="-nnvvveXXSs0"

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
echo "Using options: ${OPTS}"

if ! tcpdump "$OPTS" -w "$OUTPUT" -i "$1"; then
  exit 1
fi

exit 0
