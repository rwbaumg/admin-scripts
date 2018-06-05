#!/bin/bash
# get public ip address using ipinfo.io api

SERVICE_URL="http://ipinfo.io/ip"
# SERVICE_URL="http://ifconfig.me/ip"

if hash curl 2>/dev/null; then
  curl $SERVICE_URL
  exit 0
else
  if hash wget 2>/dev/null; then
    wget -qO- $SERVICE_URL
    exit 0
  fi
fi

# another way using just dns:
# dig +short myip.opendns.com @resolver1.opendns.com

echo >&2 "you must install either curl or wget"

exit 1
