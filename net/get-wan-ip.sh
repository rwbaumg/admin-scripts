#!/bin/bash
# Output current WAN IP
# wan_iface=$(route -n | grep -P '^0\.0\.0\.0' | awk '{ print $8 }')

if ! wan_iface=$(route -n | grep -P '^0\.0\.0\.0\s+[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\s+0\.0\.0\.0\s+[UG]{2}' | awk '{ print $8 }' | uniq | head -n1); then
  echo >&2 "ERROR: Failed to determine primary interface."
  exit 1
fi
if [ -z "${wan_iface}" ]; then
  echo >&2 "ERROR: Something went wrong trying to determine primary interface."
  exit 1
fi

err=0
if ! wan_ip=$(ifconfig "${wan_iface}" | grep -Po '(?<=inet\s)[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(?=\s)'); then
  err=1
fi
if [ "${err}" -ne 0 ] || [ -z "${wan_ip}" ]; then
  if wan_ip=$(ifconfig "${wan_iface}" | grep -Po '(?<=inet\saddr:)[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(?=\s)'); then
    err=0
  fi
fi

if [ "${err}" -ne 0 ] || [ -z "${wan_ip}" ]; then
  echo >&2 "ERROR: Failed to resolve IP address for interface '${wan_iface}'."
  exit 1
fi

echo "${wan_ip}"
exit 0
