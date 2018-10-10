#!/bin/bash
# Simple script to list logged authentication failures

AUTH_LOG="/var/log/auth.log"

# list authentication failures
FAILED=$(grep -i "failure" ${AUTH_LOG})
if [ -z "${FAILED}" ]; then
  echo "No authentication failures in logged in ${AUTH_LOG}."
  exit 0
fi

# Define regular expression parts for extracting rhost
REGEX_RHOST_START='rhost\='
REGEX_RHOST_TERM='\b'
REGEX_MATCH_IPADDR='([0-9]{1,3}[\.]){3}[0-9]{1,3}'

# Extract unique hosts which failed to authenticate
declare -a REMOTE_HOSTS=();
IFS=$'\n'; for line in ${FAILED}; do
  rhost=$(echo $line | grep -Po "(?<=\s${REGEX_RHOST_START})${REGEX_MATCH_IPADDR}(?=${REGEX_RHOST_TERM})")
  if [[ ! " ${REMOTE_HOSTS[@]} " =~ " ${rhost} " ]]; then
    REMOTE_HOSTS=("${REMOTE_HOSTS[@]}" "${rhost}")
  fi
done

# Report on authentication failures
echo >&2 "WARNING: Found authentication failures in ${AUTH_LOG}:"

echo >&2; echo >&2 "Remote hosts:"
for ((idx=0;idx<=$((${#REMOTE_HOSTS[@]}-1));idx++)); do
  rhost=${REMOTE_HOSTS[$idx]}
  echo >&2 " @ ${rhost}"
done

echo >&2; echo >&2 "Log entries:"; echo >&2 "${FAILED}"

exit 1
