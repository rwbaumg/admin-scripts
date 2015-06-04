#!/bin/bash
# super simple, uses ipinfo.io to get ip details

if [[ -z "$1" ]]; then
  echo "Usage: $0 <ip>"
  exit 1
fi

CURL_BIN=$(which curl)
REMOTE_IP=$1

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

if valid_ip $REMOTE_IP; then
  $CURL_BIN ipinfo.io/$REMOTE_IP/json
else
  echo "Invalid IP: $REMOTE_IP"
  exit 1
fi

exit 0
