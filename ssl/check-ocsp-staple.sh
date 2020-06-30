#!/bin/bash
# determine if a server has ocsp stapling enabled
# produces no output if server does not use or has
# incorrectly configured OCSP stapling.

if [[ -z "$1" ]]; then
  echo >&2 "Usage: $0 <server>"
  exit 1
fi

SERVER="$1"
SSL_PORT=443

ping_test()
{
  if [[ -z "$1" ]]; then
    echo 2
    return
  fi

  local hostname="$1"

  # todo: investigate using fping instead
  #   fping -c1 -t300 $IP
  if ! ping -c 1 "$hostname" > /dev/null 2>&1; then
    echo >&2 "$SERVER is not rresponding to ping requests and may be down."
    exit 3
  fi
}

ping_test "$SERVER"

if SSL_RESULT=$(echo QUIT | openssl s_client -connect "$SERVER:$SSL_PORT" \
                                             -servername "$SERVER" \
                                             -status > /dev/null 2>&1); then
    echo "Got response from $SERVER:$SSL_PORT (server name $SERVER)"
else
    echo >&2 "Failed to get response from server $SERVER:$SSL_PORT"
    exit $?
fi
OCSP_RESPONSE=$(echo "$SSL_RESULT" | grep -A 17 'OCSP response:' \
                                   | grep --color=never -B17 -A1 'This Update')

if [[ -z "$OCSP_RESPONSE" ]]; then
  echo >&2 "The server does not appear to have OCSP stapling."
  exit 2
fi

echo "$OCSP_RESPONSE"

exit 0
