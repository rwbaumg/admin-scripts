#!/usr/bin/env bash
# Networking helpers

function valid_url()
{
  url="$1"
  if [ -z "${url}" ]; then
    echo >&2 "No URL string was specified."
    exit 1
  fi

  hash wget 2>/dev/null || { echo >&2 "You need to install wget. Aborting."; exit 1; }
  if wget -q "${url}" -O /dev/null; then
    return 0
  fi

  return 1
}

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

    if [ -z "$ip" ]; then
        echo >&2 "ERROR: IP address cannot be null."
        return 1
    fi

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS="." read -r -a ip <<< "$ip"
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi

    return $stat
}

function valid_hostname()
{
  local host="$1"
  if [ -z "${host}" ]; then
    echo >&2 "ERROR Hostname cannot be null."
    return 1
  fi

  if [[ "$host" =~ ^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9])$ ]]; then
    return 0
  fi

  return 1
}

function get_hostname()
{
  local ip="$1"
  if [ -z "$ip" ]; then
    echo >&2 "ERROR: IP address cannot be null."
    return 1
  fi

  hash nslookup 2>/dev/null || { echo >&2 "You need to install dnsutils in order to resolve hostnames. Aborting."; exit 1; }
  if ! hostname=$(nslookup "${ip}" | grep -Po '(?<=name\s\=\s).*(?=\.)'); then
    return 1
  fi

  echo "${hostname}"
  return 0
}
