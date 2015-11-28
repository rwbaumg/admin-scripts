#!/bin/bash
# get public ip address using ipinfo.io api

if hash curl 2>/dev/null; then
  curl ipinfo.io/ip
  exit 0
else
  if hash wget 2>/dev/null; then
    wget -qO- ipinfo.io/ip
    exit 0
  fi
fi

# another way using just dns:
# dig +short myip.opendns.com @resolver1.opendns.com

echo "you must install either curl or wget"

exit 1
