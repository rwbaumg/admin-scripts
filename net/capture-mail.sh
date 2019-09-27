#!/bin/bash

IFACE="eth0"

if [ ! -z "${1}" ]; then
  IFACE="${1}"
fi

# sudo tcpdump -nn -l port 25 | grep -Ei 'MAIL FROM\|RCPT TO'
# sudo tcpdump -vv -x -X -s 1500 -i eth1 'port 25'
# sudo tcpdump -w /file/name -s 2000 host example.com and port 25IFACE="eth0"

if ! sudo tcpdump -i "${IFACE}" -l -A port 25 or port 587 | grep -Ei 'MAIL FROM|RCPT TO'; then
  exit 1
fi

exit 0
