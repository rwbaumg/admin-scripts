#!/bin/bash
#
# [ 0x19e Networks ]
#
# trade-check:
# Searches the U.S. Consolidated Screening List provided by api.trade.gov
# Enables identifying denied organizations and individuals to avoid issuing
# certificates to such entities in violation of CA/Browser Forum guidelines.
#
# Author: Robert W. Baumgartner <rwb@0x19e.net>

# Default settings
TRADE_SCREENING_API_KEY=""
TRADE_SCREENING_API_URL="https://api.trade.gov/gateway/v1/consolidated_screening_list"

# Location of the API to use
API_CALL="/search"

# Name of file containing custom options
CONFIG_NAME="trade-check.cfg"

SILENT="false"
NO_COLOR="false"

print_green()
{
  if [ "${SILENT}" != "true" ]; then
  if [ "${NO_COLOR}" == "false" ]; then
  echo -e "\x1b[39;49;00m\x1b[32;01m${1}\x1b[39;49;00m" #> $(tty) 2>&1 < $(tty)
  else
  echo "${1}" #> $(tty) 2>&1 < $(tty)
  fi
  fi
}

print_red()
{
  if [ "${SILENT}" != "true" ]; then
  if [ "${NO_COLOR}" == "false" ]; then
  echo -e "\x1b[39;49;00m\x1b[31;01m${1}\x1b[39;49;00m" #> $(tty) 2>&1 < $(tty)
  else
  echo "${1}" #> $(tty) 2>&1 < $(tty)
  fi
  fi
}

print_yellow()
{
  if [ "${SILENT}" != "true" ]; then
  if [ "${NO_COLOR}" == "false" ]; then
  echo -e "\x1b[39;49;00m\x1b[33;01m${1}\x1b[39;49;00m" #> $(tty) 2>&1 < $(tty)
  else
  echo "${1}" #> $(tty) 2>&1 < $(tty)
  fi
  fi
}

print_magenta()
{
  if [ "${SILENT}" != "true" ]; then
  if [ "${NO_COLOR}" == "false" ]; then
  echo -e "\x1b[39;49;00m\x1b[35;01m${1}\x1b[39;49;00m" #> $(tty) 2>&1 < $(tty)
  else
  echo "${1}" #> $(tty) 2>&1 < $(tty)
  fi
  fi
}

print_cyan()
{
  if [ "${SILENT}" != "true" ]; then
  if [ "${NO_COLOR}" == "false" ]; then
  echo -e "\x1b[39;49;00m\x1b[36;01m${1}\x1b[39;49;00m" #> $(tty) 2>&1 < $(tty)
  else
  echo "${1}" #> $(tty) 2>&1 < $(tty)
  fi
  fi
}

print_blue()
{
  if [ "${SILENT}" != "true" ]; then
  if [ "${NO_COLOR}" == "false" ]; then
  echo -e "\x1b[39;49;00m\x1b[34;01m${1}\x1b[39;49;00m" #> $(tty) 2>&1 < $(tty)
  else
  echo "${1}" #> $(tty) 2>&1 < $(tty)
  fi
  fi
}

exit_script()
{
  # Default exit code is 1
  local exit_code=1
  local re

  re='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'
  if echo "$1" | grep -Eq "$re"; then
    exit_code="$1"
    shift
  fi

  re='[[:alnum:]]'
  if echo "$@" | grep -Eiq "$re"; then
    if [ "$exit_code" -eq 0 ]; then
      echo >&2 "INFO: $*"
    else
      echo "ERROR: $*" 1>&2
    fi
  fi

  # Print 'aborting' string if exit code is not 0
  [ "$exit_code" -ne 0 ] && echo >&2 "Aborting script..."

  exit "$exit_code"
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename "$0")|" << "EOF" >&2
    USAGE

    Searches the U.S. Consolidated Screening List provided by api.trade.gov

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     text                    The text to search for.

    OPTIONS

     -k, --api-key <value>   Specify the API key to use.

     -q, --query <value>     (Default) Query all name fields.
     -n, --name <value>      Search the name field.
     -t, --title <value>     Search the title field.
     -a, --address <value>   Search the address field.
     -c, --country <value>   Filter results based on the country field.

     -m, --no-color          Disable colorized output (monochrome).
     -s, --silent            Do not output any text.
     -v, --verbose           Make the script more verbose.
     -h, --help              Prints this usage.

EOF

    exit_script "$@"
}

test_arg()
{
  # Used to validate user input
  local arg="$1"
  local argv="$2"

  if [ -z "$argv" ]; then
    if echo "$arg" | grep -Eq '^-'; then
      usage "Null argument supplied for option $arg"
    fi
  fi

  if echo "$argv" | grep -Eq '^-'; then
    usage "Argument for option $arg cannot start with '-'"
  fi
}

check_response() {
  if [ -z "$1" ]; then
    print_yellow >&2 "WARNING: Response is null."
    return 0
  fi

  # Check for <am:fault ... /> response
  if echo "$1" | grep -Poq '^\<am\:fault'; then
    # Error detected; parse and print
    ERROR_CODE=$(echo "${RESPONSE}" | grep -Po '(?<=\<am\:code\>)[^\<]+(?=\<\/am\:code\>)')
    ERROR_MESG=$(echo "${RESPONSE}" | grep -Po '(?<=\<am\:message\>)[^\<]+(?=\<\/am\:message\>)')
    ERROR_DESC=$(echo "${RESPONSE}" | grep -Po '(?<=\<am\:description\>)[^\<]+(?=\<\/am\:description\>)')

    if [ "${SILENT}" != "true" ]; then
      msg=0
      if [ ! -z "${ERROR_CODE}" ]; then
        print_red >&2 "Error code        : ${ERROR_CODE}"; msg=1
      fi
      if [ ! -z "${ERROR_MESG}" ]; then
        print_red >&2 "Error message     : ${ERROR_MESG}"; msg=1
      fi
      if [ ! -z "${ERROR_DESC}" ]; then
        print_red >&2 "Error description : ${ERROR_DESC}"; msg=1
      fi
      if [ "${msg}" -lt "1" ]; then
        print_red >&2 "ERROR: Service returned AM fault."
      fi
    fi

    exit 1
  fi

  # Check for <ams:fault ... /> response
  if echo "$1" | grep -Poq '^\<ams\:fault'; then
    # Error detected; parse and print
    ERROR_CODE=$(echo "${RESPONSE}" | grep -Po '(?<=\<ams\:code\>)[^\<]+(?=\<\/ams\:code\>)')
    ERROR_MESG=$(echo "${RESPONSE}" | grep -Po '(?<=\<ams\:message\>)[^\<]+(?=\<\/ams\:message\>)')
    ERROR_DESC=$(echo "${RESPONSE}" | grep -Po '(?<=\<ams\:description\>)[^\<]+(?=\<\/ams\:description\>)')

    if [ "${SILENT}" != "true" ]; then
      msg=0
      if [ ! -z "${ERROR_CODE}" ]; then
        print_red >&2 "Error code        : ${ERROR_CODE}"; msg=1
      fi
      if [ ! -z "${ERROR_MESG}" ]; then
        print_red >&2 "Error message     : ${ERROR_MESG}"; msg=1
      fi
      if [ ! -z "${ERROR_DESC}" ]; then
        print_red >&2 "Error description : ${ERROR_DESC}"; msg=1
      fi
      if [ ${msg} -lt 1 ]; then
        print_red >&2 "ERROR: Service returned AMS fault."
      fi
    fi

    exit 1
  fi

  return 0
}

SEARCH_TXT=""
SEARCH_MODE=""
VERBOSITY=0
COUNTRY_CODE=""

VERBOSITY=0
VERBOSE=""
check_verbose()
{
  if [ $VERBOSITY -gt 3 ]; then
    VERBOSE="-v"
  fi
  if [ $VERBOSITY -gt 4 ]; then
    VERBOSE="-vv"
  fi
  if [ $VERBOSITY -gt 5 ]; then
    VERBOSE="-vvv"
  fi
}

test_mode()
{
  if [ ! -z "${SEARCH_MODE}" ]; then
    usage "Cannot specify conflicting options."
  fi
}

# Load configuration
CONFIG="$(readlink -m "$(dirname "$0")/${CONFIG_NAME}")"
if [ -e "${CONFIG}" ]; then
  print_yellow >&2 "Loading configuration file '${CONFIG}' ..."

  # Source configuration file
  # shellcheck source=/dev/null
  source "${CONFIG}"
#else
#  print_yellow >&2 "WARNING: Configuration file not found: ${CONFIG}"
fi

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -k|--api-key)
      test_arg "$1" "$2"
      shift
      TRADE_SCREENING_API_KEY="$1"
      shift
    ;;
    -a|--address)
      test_mode
      test_arg "$1" "$2"
      shift
      SEARCH_MODE="address"
      SEARCH_TXT="$1"
      shift
    ;;
    -c|--country)
      if [ ! -z "${COUNTRY_FILTER}" ]; then
        usage "Cannot specify multiple country filters."
      fi
      test_arg "$1" "$2"
      shift
      COUNTRY_CODE="${1}"
      shift
    ;;
    -n|--name)
      test_mode
      test_arg "$1" "$2"
      shift
      SEARCH_MODE="name"
      SEARCH_TXT="$1"
      shift
    ;;
    -t|--title)
      test_mode
      test_arg "$1" "$2"
      shift
      SEARCH_MODE="title"
      SEARCH_TXT="$1"
      shift
    ;;
    -q|--query)
      test_mode
      test_arg "$1" "$2"
      shift
      SEARCH_MODE="q"
      SEARCH_TXT="$1"
      shift
    ;;
    -m|--no-color)
      NO_COLOR="true"
      shift
    ;;
    -h|--help)
      usage
    ;;
    -s|--silent)
      SILENT="true"
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      check_verbose
      shift
    ;;
    -vv)
      ((VERBOSITY++))
      ((VERBOSITY++))
      check_verbose
      shift
    ;;
    -vvv)
      ((VERBOSITY++))
      ((VERBOSITY++))
      ((VERBOSITY++))
      check_verbose
      shift
    ;;
    *)
      if [ ! -z "${SEARCH_TXT}" ]; then
        usage "Cannot specify multiple search terms."
      fi
      test_arg "$1"
      SEARCH_MODE="q"
      SEARCH_TXT="$1"
      shift
    ;;
  esac
done

hash curl 2>/dev/null || { usage "You need to install curl."; }
hash jq 2>/dev/null || { usage "You need to install jq."; }

# Check if an API key is available.
if [ -z "${TRADE_SCREENING_API_KEY}" ]; then
  usage "No API key supplied; unable to perform check."
elif [ ${VERBOSITY} -gt 0 ]; then
  if [ ${VERBOSITY} -gt 1 ]; then
  print_cyan >&2 "Using API URL : ${TRADE_SCREENING_API_URL}"
  fi
  print_cyan >&2 "Using API Key : ${TRADE_SCREENING_API_KEY}"
fi

if [ -z "${COUNTRY_CODE}" ]; then
  if [ -z "${SEARCH_MODE}" ] ; then
    usage "Search mode not defined."
  fi
  if [ -z "${SEARCH_TXT}" ]; then
    usage "Search text cannot be null."
  fi

  if [ "${SILENT}" != "true" ]; then
    if [ ${VERBOSITY} -gt 0 ]; then
      print_cyan >&2 "Search mode   : $SEARCH_MODE" #> $(tty) 2>&1 < $(tty)
      print_cyan >&2 "Search text   : $SEARCH_TXT" #> $(tty) 2>&1 < $(tty)
    fi
  fi
fi

if [ "${SEARCH_MODE}" == "q" ]; then
  print_yellow >&2 "Checking U.S. Consolidated Screening List for '${SEARCH_TXT}'..."
elif [ ! -z "${COUNTRY_CODE}" ]; then
  print_yellow >&2 "Checking U.S. Consolidated Screening List for countries '${COUNTRY_CODE}'..."
else
  print_yellow >&2 "Checking U.S. Consolidated Screening List for ${SEARCH_MODE} '${SEARCH_TXT}'..."
fi

# Check for missing diff support
declare -a curl_params=();
function add_parameters() {
  if [ -z "$*" ]; then
    echo >&2 "ERROR: Package name cannot be null."
    exit 1
  fi
  #if echo "${curl_params[@]}" | grep -q -w "$*"; then
  #  echo >&2 "ERROR: Parameter configured multiple times: '$*'"
  #  return 1
  #fi

  curl_params=("${curl_params[@]}" "$@")
  return 0
}

function get_parameters() {
  if [[ ${#curl_params[@]} -lt 1 ]]; then
    echo >&2 "ERROR: No parameters configured."
    return 1
  fi

  echo "${curl_params[@]}"
}

function add_header() {
  if [ -z "$1" ]; then
    echo >&2 "ERROR: No value supplied for header."
    return 1
  fi

  if ! add_parameters "--header" "$1"; then
    return 1
  fi

  return 0
}

function add_param() {
  if [ -z "$1" ]; then
    echo >&2 "ERROR: No value supplied for parameter key."
    return 1
  fi
  if [ -z "$2" ]; then
    echo >&2 "ERROR: No value supplied for parameter value."
    return 1
  fi

  if ! add_parameters "--data-urlencode" "${1}=${2}"; then
    return 1
  fi

  return 0
}

# Configure authorization header
if [ ! -z "${TRADE_SCREENING_API_KEY}" ]; then
  add_header "Authorization: Bearer ${TRADE_SCREENING_API_KEY}"
fi

# Configure country filter
if [ ! -z "${COUNTRY_CODE}" ]; then
  add_param "countries" "${COUNTRY_CODE}"
fi

# Configure curl command line for requested search parameters
if [ ! -z "${SEARCH_MODE}" ] && [ ! -z "${SEARCH_TXT}" ]; then
  add_param "${SEARCH_MODE}" "${SEARCH_TXT}"
fi

# Combine curl arguments
CURL_ARGS=("-s" "-S" "-G" "${curl_params[@]}")

if [ ${VERBOSITY} -gt 2 ]; then
  print_cyan >&2 "Raw command:"
  print_cyan >&2 "---"
  print_blue >&2 "curl ${VERBOSE} ${CURL_ARGS[*]} ${TRADE_SCREENING_API_URL}${API_CALL}"
  print_cyan >&2 "---"
fi

if ! RAW_RESPONSE=$(curl ${VERBOSE} "${CURL_ARGS[@]}" --write-out "\n%{http_code}" "${TRADE_SCREENING_API_URL}${API_CALL}"); then
  print_red >&2 "ERROR: Failed to get response from server."
  exit 1
fi
if [ -z "${RAW_RESPONSE}" ]; then
  exit_script 1 "Null response from server."
fi
if ! RESPONSE=$(echo "${RAW_RESPONSE}" | sed -e '$ d'); then
  exit_script 1 "Failed to parse response."
fi
if ! STATUSCODE=$(echo "${RAW_RESPONSE}" | tail -n1); then
  exit_script 1 "Failed to parse status code from response."
fi

if [ ${VERBOSITY} -gt 2 ]; then
  print_cyan >&2 "Raw response :"
  print_cyan >&2 "---"
  if [ ! -z "${RESPONSE}" ]; then
  print_blue >&2 "${RESPONSE}"
  fi
  print_cyan >&2 "---"
fi

# Get response
if [ "${STATUSCODE}" != "200" ]; then
  exit_script 1 "Failed to perform search; server returned code ${STATUSCODE}."
fi
if [ -z "${RESPONSE}" ]; then
  exit_script 1 "The server returned an empty response."
fi

# Validate response
if ! check_response "${RESPONSE}"; then
  exit 1
fi

# Check for errors in response
ERRORS=$(echo "${RESPONSE}" | jq -r ".error")
if [ ! -z "${ERRORS}" ] && [ ! "${ERRORS}" == "null" ]; then
  if [ "${SILENT}" != "true" ]; then
  if [ ${VERBOSITY} -gt 1 ]; then
  if [ "${NO_COLOR}" == "false" ]; then
  echo "${RESPONSE}" | jq -r -C
  else
  echo "${RESPONSE}" | jq -r -M
  fi
  fi
  print_red >&2 "ERROR: ${ERRORS}"
  fi
  exit 1
fi

# Report on data sources
if [ ${VERBOSITY} -gt 1 ] && [ "${SILENT}" != "true" ]; then
  SOURCE_LIST=$(echo "${RESPONSE}" | jq -r ".sources_used[].source")
  SOURCE_COUNT=$(echo "${SOURCE_LIST}" | wc -l)

  print_cyan >&2 "Query checked ${SOURCE_COUNT} source(s):"
  echo "${SOURCE_LIST}" | while read -r source; do
    print_magenta >&2 "-  ${source}"
  done
fi

# Parse response
RESULTS=$(echo "${RESPONSE}" | jq -r ".results")
TOTAL=$(echo "${RESPONSE}" | jq -r ".total")
if [ -z "${TOTAL}" ] | [ "${TOTAL}" == "null" ]; then
  print_yellow >&2 "Service returned null."
  exit 0
elif [ "${TOTAL}" == "0" ]; then
  print_green "No results returned."
  exit 0
fi

print_red >&2 "WARNING: Found ${TOTAL} result(s):"

# Print results
if [ "${SILENT}" != "true" ]; then
if [ "${NO_COLOR}" == "false" ]; then
  echo "${RESULTS}" | jq -C .
else
  echo "${RESULTS}"
fi
fi

exit 2
