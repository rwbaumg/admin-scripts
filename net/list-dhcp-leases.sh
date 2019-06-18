#!/bin/bash

DHCPD_LEASES="/var/lib/dhcp/dhcpd.leases"

if [ ! -e "${DHCPD_LEASES}" ]; then
  echo >&2 "ERROR: DHCP daemon leases cache file '${DHCPD_LEASES}' does not exist."
  exit 1
fi

cat "${DHCPD_LEASES}"

exit 0
