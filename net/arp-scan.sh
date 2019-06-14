#!/bin/bash
#
# [0x19e Networks]
#
# arp-scan.sh - scan for hosts using ARP
# author: Robert W. Baumgartner <rwb@0x19e.net>
#
# Perform an arp scan on the primary interface
#
# This script tries to identify the correct interface
# by examining the default route to reach a host
# on the target network. The resolved IP is again
# used to perform a IPv4 route lookup to find the
# interface being used.
#
# There are several ways to identify the target
# interface automatically:
#
# Using 'route':
#   route | grep '^default' | grep -o '[^ ]*$'
#
# Using 'ip':
#   ip -4 route ls | grep '^default' | grep -Po '(?<=dev )(\S+)'
#
# To resolve the first IP address given a hostname:
#   getent ahosts 0x19e.net | awk '{ print $1; exit}'
#
# To get the interface used to contact the outside web:
#   ip -4 route get 10.6.6.8 | grep -Po '(?<=dev )(\S+)'

# make sure required commands are installed
hash grep 2>/dev/null || { echo >&2 "You need to install grep. Aborting."; exit 1; }
hash arp-scan 2>/dev/null || { echo >&2 "You need to install arp-scan. Aborting."; exit 1; }

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# get the interface for scanning
IFACE_HOST="0x19e.net"
IFACE_NAME=$(ip -4 route get "$(getent ahosts $IFACE_HOST | awk '{ print $1; exit}')" | grep -Po '(?<=dev )(\S+)')

# perform the scan
arp-scan -l --interface "$IFACE_NAME"

exit 0
