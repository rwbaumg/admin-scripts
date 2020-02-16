#!/bin/bash
## Check for a working ToR connection

hash curl 2>/dev/null || { echo >&2 "You need to install curl. Aborting."; exit 1; }

TEST_URL="https://check.torproject.org"

if ! RESULT=$(curl -s "${TEST_URL}" | grep -E "Sorry|Congratulations" | head -n1 | sed -e 's/^[ \t]*//'); then
  echo >&2 "ERROR: Failed to connect to test server."
  exit 1
fi

# Print the result to stdout
echo "${RESULT}"

if echo "${RESULT}" | grep -qE "Sorry"; then
  # echo >&2 "ERROR: Tor is inactive or not configured correctly."
  exit 1
fi

exit 0
