#!/bin/bash
# curl https://www.commandlinefu.com/commands/browse/sort-by-votes/plaintext/"[0-2499:25]" | grep -v _curl_ > comfu.txt

OUTPUT_FILE="cmdfu.txt"

CMDFU_PROTOCOL="https"
CMDFU_DNS_NAME="www.commandlinefu.com"
CMDFU_BASE_URL="/commands/browse/sort-by-votes/plaintext"
CMDFU_CMDRANGE="[0-2499:25]"

HTTP_REQUEST="GET"
REQUEST_ARGS="--compressed -s"
# REQUEST_ARGS="--compressed --progress-bar"

CURL_BASE_COMMAND="curl ${REQUEST_ARGS} --request ${HTTP_REQUEST}"
CMDFU_REQUEST_URL="${CMDFU_PROTOCOL}://${CMDFU_DNS_NAME}/${CMDFU_BASE_URL}"

function get_response_from_url()
{
  local url="$1"
  if [ -z "${url}" ]; then
    echo >&2 "ERROR: URL cannot be null."
    exit 1
  fi

  if ! RESPONSE_RAW=$(${CURL_BASE_COMMAND} "${url}"); then
    echo >&2 "ERROR: An error was encounterd while retrieving a response from the server ('${CMDFU_DNS_NAME}')."
    exit 1
  fi
  if [ -z "${RESPONSE_RAW}" ]; then
    echo >&2 "ERROR: Server response was null."
    return 1
  fi

  echo -n "${RESPONSE_RAW}"
  return 0
}

function get_response_code_from_url()
{
  local url="$1"
  if [ -z "${url}" ]; then
    echo >&2 "ERROR: URL cannot be null."
    exit 1
  fi

  if ! RESPONSE_RAW=$(${CURL_BASE_COMMAND} --head "${url}"); then
    echo >&2 "ERROR: An error was encounterd while retrieving a response code from the server ('${CMDFU_DNS_NAME}')."
    exit 1
  fi
  if [ -z "${RESPONSE_RAW}" ]; then
    echo >&2 "ERROR: Server response was null."
    return 1
  fi

  echo -n "${RESPONSE_RAW}" | grep -Po '^(?:HTTP/[012\.]+\s)[0-9]+\s' | awk '{ print $2 }'
  return 0
}

function check_response_code()
{
  local response="$1"
  if [ -z "${response}" ]; then
    echo >&2 "ERROR: Response code cannot be null."
    exit 1
  fi

  if ! echo "${response}" | grep -qPo "^200$" > /dev/null; then
    echo >&2 "ERROR: Server returned an unexpected response code: ${response}"
    return 1
  fi

  return 0
}

if ! SERVER_RESPONSE_CODE=$(get_response_code_from_url "${CMDFU_REQUEST_URL}"); then
  exit 1
fi
if ! check_response_code "${SERVER_RESPONSE_CODE}"; then
  exit 1
fi

echo "Remote server responded with code ${SERVER_RESPONSE_CODE}; pulling data..."
echo "cURL Command: '${CURL_BASE_COMMAND} \"${CMDFU_REQUEST_URL}/${CMDFU_CMDRANGE}\"'"
echo "Downloading from URL: '${CMDFU_REQUEST_URL}' ..."

if ! ${CURL_BASE_COMMAND} -o "${OUTPUT_FILE}" "${CMDFU_REQUEST_URL}/${CMDFU_CMDRANGE}"; then
  echo >&2 "ERROR: An error was encounterd while retrieving a response from the server ('${CMDFU_DNS_NAME}')."
  exit 1
fi

echo "Saved results to '$(readlink -f "${OUTPUT_FILE}")'."
exit 0
