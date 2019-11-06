#!/bin/bash

IFACE="eth0"

if [ ! -z "${1}" ]; then
  IFACE="${1}"
fi

if ! sudo tcpdump -i "${IFACE}" port http or port ftp or port smtp or port imap or port pop3 or port telnet -l -A | grep -Ei -B5 'pass=|pwd=|log=|login=|user=|username=|pw=|passw=|passwd=|password=|pass:|user:|username:|password:|login:|pass |user '; then
  exit 1
fi

exit 0
