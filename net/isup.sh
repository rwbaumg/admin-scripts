#!/bin/bash
# checks if a site is up and available
# by sending an HTTP request using cURL
#
# Example:
# if curl -s --head --request GET https://www.google.com \
#      | grep -Po '^(?:HTTP/[012\.]+\s)[0-9]+\s' \
#      | awk '{ print $2 }' \
#      | grep -Po '^200$' > /dev/null; then
#   echo "is up!"
# fi

TARGET_URL="$1"
if [ -z "${TARGET_URL}" ]; then
  echo >&2 "Usage: $0 <url>"
  exit 1
fi

# define the regex used to determine if a site is up
ISUP_REGEX="^200$"

# configure the request type
CURL_REQUEST="GET"

# perform the request
RESPONSE=$(curl -s --head --request GET ${TARGET_URL})
RESPONSE_CODE=$(echo -n "${RESPONSE}" | grep -Po '^(?:HTTP/[012\.]+\s)[0-9]+\s' | awk '{ print $2 }')

echo "Test website  : ${TARGET_URL}"
echo "Response code : ${RESPONSE_CODE}"

if echo "${RESPONSE_CODE}" | grep -Po "${ISUP_REGEX}" > /dev/null; then
  echo "${TARGET_URL} is up!"
  exit 0
fi

echo >&2 "${RESPONSE_URL} is down."
exit 1
