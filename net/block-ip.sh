#!/bin/bash
# Blocks an IP address for 2 hours

if [[ -z "$1" ]]; then
  echo "Usage: $0 <ip>"
  exit 1
fi

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Set the offending IP
REMOTE_IP=$1

# Path to iptables binary executed by user apache through sudo
IPTABLES="/sbin/iptables"

# The action to use for the blocking rule
IPTABLES_ACTION="DROP"

# set the lock file. this file will be removed after the block is lifted.
LOCKDIR=/tmp
LOCKFILE="$LOCKDIR"/dos-"$REMOTE_IP"

# Test an IP address for validity:
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
#
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Add a firewall rule to block offending IP
# Unblock offending IP after 2 hours through the 'at' command (see 'man at' for further details)
# Remove lock file for future checks

if valid_ip $REMOTE_IP; then
  $IPTABLES -I INPUT -s $REMOTE_IP -j $IPTABLES_ACTION
  echo "$IPTABLES -D INPUT -s $REMOTE_IP -j $IPTABLES_ACTION" | at now + 2 hours
  rm -f "$LOCKFILE"
else
  echo "Invalid IP: $REMOTE_IP"
  exit 1
fi

exit 0
