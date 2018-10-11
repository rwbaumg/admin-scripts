#!/bin/bash
# Generates random 64-bit non-negative hexadecimal value

hash openssl 2>/dev/null || { echo >&2 "You need to install openssl. Aborting."; exit 1; }

DEFAULT_SERIAL="01"

HEX_COUNT=16
MAX_TRIES=100

# Get a fresh, non-negative, random serial
COUNT=0
SERIAL=$(openssl rand -hex ${HEX_COUNT})
while [ ${COUNT} -lt ${MAX_TRIES} ] && [ $((0x${SERIAL})) -lt 0 ]; do
  SERIAL=$(openssl rand -hex ${HEX_COUNT})
  ((COUNT++))
done
if [ ${COUNT} -ge ${MAX_TRIES} ]; then
  echo ${DEFAULT_SERIAL}
  exit 1
fi

echo ${SERIAL}
exit 0
