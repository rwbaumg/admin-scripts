#!/bin/bash
#./update-port-list

if [ -z "$1" ]; then
  echo >&2 "Usage: $0 <port>"
  exit 1
fi

INC_DESC="false"
PORTS_MAP_FILE="$(dirname "$0")/service-names-port-numbers.csv"
DOWNLOAD_URL="http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv"

hash awk 2>/dev/null || { echo >&2 "You need to install awk. Aborting."; exit 1; }
hash wget 2>/dev/null || { echo >&2 "You need to install wget. Aborting."; exit 1; }

function download_map()
{
  if [ -z "${DOWNLOAD_URL}" ]; then
    echo >&2 "ERROR: Download URL is not configured."
    exit 1
  fi

  if ! wget --quiet -O "${PORTS_MAP_FILE}" "$DOWNLOAD_URL"; then
    return 1
  fi

  return 0
}

if [ ! -e "${PORTS_MAP_FILE}" ] || [ ! -s "${PORTS_MAP_FILE}" ]; then
  if hash wget 2>/dev/null ; then
    if ! download_map; then
      echo >&2 "ERROR: Failed to download port map."
      exit 1
    else
      echo "Downloaded missing ports map from ${DOWNLOAD_URL}"
    fi
  else
    echo >&2 "ERROR: Ports database '${PORTS_MAP_FILE}' does not exist."
    exit 1
  fi
fi

if [ "$INC_DESC" == "true" ]; then
  # Include description
  grep -v "IANA assigned" "${PORTS_MAP_FILE}" | grep -P '^[^\s]' | grep ",," \
       | awk  -F"," '("$5" != "[John_Fake]") && (length($1) > 0) && (length($2) > 0) && (length($3) > 0) {printf("%-40s %-60s %s/%s\n", $1, substr($4, 1, 55), $2, $3)}' \
       | grep -i -P "(^|\\s)$1(\\s|\/tcp|\/udp|$)?"
else
  # Name only
  grep -v "IANA assigned" "${PORTS_MAP_FILE}" | grep -P '^[^\s]' | grep ",," \
       | awk  -F"," '("$5" != "[John_Fake]") && (length($1) > 0) && (length($2) > 0) && (length($3) > 0) {printf("%-40s %s/%s\n", $1, $2, $3)}' \
       | grep -i -P "(^|\\s)$1(\\s|\/tcp|\/udp|$)?"
fi

exit 0
