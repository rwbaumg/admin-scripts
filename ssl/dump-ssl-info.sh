#!/bin/bash
# print openssl info for a given site

DEFAULT_PORT=443

if [[ -z "$1" ]]; then
  echo >&2 "Usage: $0 <server> [port]"
  exit 1
fi

# re='^(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'
re='^[-A-Za-z0-9\+&@#%?=~_|!:,.;]+$'
if ! [[ $1 =~ $re ]]; then
  echo >&2 "ERROR: Invalid server name"
  exit 1
fi

# figure out what port to try
SP=$DEFAULT_PORT
if [[ ! -z "$2" ]]; then
  re='^[0-9]+$'
  if ! [[ $2 =~ $re ]]; then
    echo >&2 "ERROR: Port must be a valid number"
  fi
  SP=$2
fi

SERVER="$1"
PORT="$SP"
if ! timeout 2 bash -c "echo QUIT | openssl s_client -CApath /etc/ssl/certs -connect $SERVER:$PORT -servername $SERVER -status"; then
  echo >&2 "ERROR: Failed to connect to server."
  exit 1
fi

exit 0
