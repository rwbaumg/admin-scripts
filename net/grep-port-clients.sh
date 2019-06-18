#!/bin/bash

LOGFILE="/var/log/syslog"

IFACE="wan"
# IFACE="fwbr.wan"

PORT="$1"
if [ -z "${PORT}" ]; then
  echo "Usage: $0 <port> [iface]"
  exit 1
fi
if [ -n "$2" ]; then
  IFACE="$2"
fi
if [ -n "$3" ]; then
  LOGFILE="$3"
fi

if [ ! -e "${LOGFILE}" ]; then
  echo >&2 "ERROR: The specified logfile '${LOGFILE}' does not exist."
  exit 1
fi

function get_hostname()
{
  local ip="$1"
  if [ -z "$ip" ]; then
    echo >&2 "ERROR: IP address cannot be null."
    exit 1
  fi

  if ! hostname=$(nslookup "${ip}" | grep -Po '(?<=name\s\=\s).*(?=\.)'); then
    return 1
  fi

  echo "${hostname}"
  return 0
}

echo >&2 "Incoming connections to TCP port $PORT on interface '${IFACE}' (logfile: ${LOGFILE}):"
echo >&2 "--"

# To get the interface:
# grep -Po '(?<=IN\=)[^\s]+(?=\s)'

IFS=$'\n'; for src in $(grep -ni "DPT=${PORT}" "${LOGFILE}" | grep -P "(?<=IN\\=)([^\\s]+)?${IFACE/\./\\.}([^\\s]+)?(?=\\s)" | grep -Po '(?<=SRC\=)([0-9]+(\.)?){1,4}' | uniq -c | sort -rn); do
  count=$(echo "${src}" | awk -F' ' '{ print $1 }')
  ip=$(echo "${src}" | awk -F' ' '{ print $2 }')
  if [ -n "$ip" ]; then
    host=$(get_hostname "$ip")
    printf "%s \\t %-20s %s\\n" "$count" "$ip" "$host"
  fi
done

echo >&2 "--"
exit 0

