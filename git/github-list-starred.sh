#!/bin/bash
# Get all starred repositories for a given GitHub user

# (Optional) Configure default user
DEFAULT_USER=""

# The GitHub API token to use.
# If not specified here, the key can be provided either by storing it in a file
# in the same directory as this script or through theh command line.
API_TOKEN=""

# The name of the file containing the GitHub API key to use.
API_KEY_FILENAME=".api-key"

# Get desired GitHub username and store in GITHUB_USER
GITHUB_USER=${1:-$DEFAULT_USER}
#if [ -z "${GITHUB_USER}" ]; then
#  echo "Usage: $0 <username>"
#  exit 1
#fi

exit_script()
{
  # Default exit code is 1
  local exit_code=1
  local re

  re='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'
  if echo "$1" | grep -qE "$re"; then
    exit_code=$1
    shift
  fi

  re='[[:alnum:]]'
  if echo "$*" | grep -iqE "$re"; then
    if [ "$exit_code" -eq 0 ]; then
      echo "INFO: $*"
    else
      echo "ERROR: $*" 1>&2
    fi
  fi

  # Print 'aborting' string if exit code is not 0
  [ "$exit_code" -ne 0 ] && echo "Aborting script..."

  exit "$exit_code"
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename "$0")|" << EOF
    USAGE

    Dumps a list of a GitHub user's starred repositories.

    SYNTAX
            SCRIPT_NAME [OPTIONS] [ARGUMENTS]

    ARGUMENTS

     username                The GitHub user to dump stars from.

    OPTIONS

     -k, --api-key <value>   Set the GitHub API key to use for authentication.
     -o, --output <value>    Specify the path to save results to.

     -c, --csv               Use CSV formatting for output.
     -p, --stdout            Print to <stdout> instead of saving to file.

     --no-header             Do not include a column header.

     -f, --force             Overwrite existing output file.
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
    if echo "$arg" | grep -qE '^-'; then
      usage "Null argument supplied for option $arg"
    fi
  fi

  if echo "$argv" | grep -qE '^-'; then
    usage "Argument for option $arg cannot start with '-'"
  fi
}

# shellcheck source=/dev/null
function load_api_key() {
  api_key_file="$(dirname "$0")/${API_KEY_FILENAME}"
  if [ ! -e "${api_key_file}" ]; then
    echo >&2 "WARNING: Missing API keyfile: ${api_key_file}"
    return 1
  elif ! source "${api_key_file}"; then
    echo >&2 "ERROR: Failed to load API key: ${api_key_file}"
    return 1
  fi

  return 0
}

NO_HEADER="false"
CSV_MODE="false"
USE_STDOUT="false"
OUT_FILE=""
FORCE="false"
VERBOSITY=0
USER_ARGC=0
#VERBOSE=""
#check_verbose()
#{
#  if [ $VERBOSITY -gt 1 ]; then
#    VERBOSE="-v"
#  fi
#}

# process arguments
#[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -k|--api-key)
      test_arg "$1" "$2"
      shift
      API_TOKEN="$1"
      shift
    ;;
    -o|--output)
      test_arg "$1" "$2"
      shift
      OUT_FILE="$1"
      shift
    ;;
    -p|--stdout)
      USE_STDOUT="true"
      shift
    ;;
    -f|--force)
      FORCE="true"
      shift
    ;;
    -c|--csv)
      CSV_MODE="true"
      shift
    ;;
    --no-header)
      NO_HEADER="true"
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      #check_verbose
      shift
    ;;
    -vv)
      ((VERBOSITY++))
      ((VERBOSITY++))
      #check_verbose
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      if [ ${USER_ARGC} -ge 1 ]; then
        usage "Cannot specify multiple usernames."
      fi
      test_arg "$1"
      GITHUB_USER="$1"
      ((USER_ARGC++))
      shift
    ;;
  esac
done

FORMAT_ID="tsv"
FIELDS_LIST=".repo.stargazers_count,.repo.pushed_at,.repo.size,.repo.clone_url"
if [ "${CSV_MODE}" == "true" ]; then
  FORMAT_ID="csv"
  FIELDS_LIST=".starred_at,${FIELDS_LIST},.repo.description"
fi

if [ -z "${GITHUB_USER}" ]; then
  usage "Must supply a GitHub username."
fi

if [ "${USE_STDOUT}" != "true" ]; then
  if [ -z "${OUT_FILE}" ]; then
    if [ "${CSV_MODE}" == "true" ]; then
      OUT_FILE="${GITHUB_USER}-starred-$(date '+%Y%m%d').csv"
    else
      OUT_FILE="${GITHUB_USER}-starred-$(date '+%Y%m%d').list"
    fi
  fi
  if [ -e "${OUT_FILE}" ] && [ "${FORCE}" != "true" ]; then
    usage "Output file '${OUT_FILE}' already exists; use -f/--force to overwrite."
  fi
fi

if [ -z "${API_TOKEN}" ]; then
  if ! load_api_key; then
    echo >&2 "WARNING: Making requests without an available API key!"
  fi
fi

auth_header=""
if [ -n "${API_TOKEN}" ]; then
  auth_header="-H \"Authorization: token ${API_TOKEN}\""
  echo >&2 "Using GitHub API token: ${API_TOKEN}"
else
  echo >&2 "WARNING: No GitHub API token was supplied; results may be incomplete."
fi

function get_starred() {
  if [ "${STARS}" -lt 1 ]; then
    echo >&2 "ERROR: Star count for ser ${GITHUB_USER} is zero."
    return 1
  fi
  PAGES=$((STARS/100+1))
  for PAGE in $(seq $PAGES); do
      echo >&2 "Getting page ...... (${PAGE}/${PAGES})"
      curl_cmd="curl -sf ${auth_header} -H \"Accept: application/vnd.github.v3.star+json\" \"https://api.github.com/users/${GITHUB_USER}/starred?per_page=100&page=${PAGE}\""

      if [ $VERBOSITY -gt 0 ]; then
        echo >&2 "DEBUG: Running command: '${curl_cmd}'"
      fi

      if ! response=$(bash -c "${curl_cmd}"); then
        echo >&2 "ERROR: Failed to retrieve page ${PAGE}."
        return 1
      fi
      if ! echo "${response}" | jq -r ".[]|[${FIELDS_LIST}]|@${FORMAT_ID}"; then
        echo >&2 "ERROR: Failed to parse page ${PAGE}."
        return 1
      fi
  done

  return 0
}

curl_cmd="curl -fSsI ${auth_header} \"https://api.github.com/users/${GITHUB_USER}/starred?per_page=1\""
if [ $VERBOSITY -gt 0 ]; then
  echo >&2 "DEBUG: Running command: '${curl_cmd}'"
fi
if ! stars_response=$(bash -c "${curl_cmd}"); then
  response_code=$(echo "${stars_response}" | grep -Po "(?<=Status\:\s)[0-9]+")
  if [ -z "${response_code}" ] && [ -n "${stars_response}" ]; then
    echo >&2 "${stars_response}"
  elif [ -n "${response_code}" ]; then
    echo >&2 "ERROR: Failed to determine starred repositories for user ${GITHUB_USER} (response: ${response_code})."
  else
    echo >&2 "ERROR: Failed to determine starred repositories for user ${GITHUB_USER}."
  fi
  exit 1
fi
if ! STARS=$(echo "${stars_response}" | grep -E '^Link' | grep -Eo 'page=[0-9]+' | tail -1 | cut -c6-); then
  echo >&2 "ERROR: Failed to determine number of starred repositories for user ${GITHUB_USER}."
  exit 1
fi
echo >&2 "Found ${STARS} starred repositories for user '${GITHUB_USER}'"

if ! starred_list=$(get_starred); then
  echo >&2 "WARNING: An error was encountered while downloading list; results may be incomplete."
fi

if [ "${CSV_MODE}" == "true" ]; then
  column_hdr='"Starred At","Stargazers","Last Pushed At","Repository Size","Clone URL","Description"\n'
else
  column_hdr="Stars\tLast Pushed At\t\tSize\tClone URL\n"
fi

if [ "${USE_STDOUT}" == "true" ]; then
  # dump the entire list to stdout
  echo >&2 "Printing list..."
  if [ "${NO_HEADER}" != "true" ]; then
    echo -ne "${column_hdr}"
  fi
  echo "${starred_list}"
else
  echo >&2 "Dumping list to ${OUT_FILE} ..."
  if [ "${NO_HEADER}" != "true" ]; then
    echo -ne "${column_hdr}" > "${OUT_FILE}"
  fi
  echo "${starred_list}" >> "${OUT_FILE}"
fi

echo >&2 "Finished dumping ${STARS} starred repositories for user ${GITHUB_USER}."
exit 0
