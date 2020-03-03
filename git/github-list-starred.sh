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
if [ -z "${GITHUB_USER}" ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

# shellcheck source=/dev/null
function load_api_key() {
  api_key_file="$(dirname "$0")/${API_KEY_FILENAME}"
  if [ ! -e "${api_key_file}" ]; then
    echo >&2 "WARNING: Missing API keyfile: ${api_key_file}"
    echo >&2 "WARNING: Results might be missing; you should put your API key in '${api_key_file}'"
    return 1
  elif ! source "${api_key_file}"; then
    echo >&2 "ERROR: Failed to load API key: ${api_key_file}"
    return 1
  fi

  return 0
}

if ! load_api_key; then
  echo >&2 "WARNING: Making requests without an available API key!"
fi

auth_header=""
if [ -n "${API_TOKEN}" ]; then
  auth_header="-H "-H ""Authorization: token ${API_TOKEN}""""
fi


function get_starred() {
  if [ "${STARS}" -lt 1 ]; then
    echo >&2 "ERROR: Star count for ser ${GITHUB_USER} is zero."
    return 1
  fi
  PAGES=$((STARS/100+1))
  for PAGE in $(seq $PAGES); do
      echo >&2 "Getting page ...... (${PAGE}/${PAGES})"
      if ! response=$(curl -sf ${auth_header} -H "Accept: application/vnd.github.v3.star+json" \
            "https://api.github.com/users/${GITHUB_USER}/starred?per_page=100&page=${PAGE}"); then
        echo >&2 "ERROR: Failed to retrieve page ${PAGE}."
        return 1
      fi
      if ! echo "${response}" | jq -r '.[]|[.repo.stargazers_count,.repo.pushed_at,.repo.clone_url,.repo.size]|@tsv'; then
        echo >&2 "ERROR: Failed to parse page ${PAGE}."
        return 1
      fi
  done

  return 0
}

if ! stars_response=$(curl -fSsI ${auth_header} "https://api.github.com/users/${GITHUB_USER}/starred?per_page=1"); then
  response_code=$(echo "${stars_response}" | grep -Po "(?<=Status\:\s)[0-9]+")
  if [ -z "${response_code}" ]; then
    echo >&2 "${stars_response}"
  else
    echo >&2 "ERROR: Failed to determine starred repositories for user ${GITHUB_USER} (response: ${response_code})."
  fi
  exit 1
fi
if ! STARS=$(echo "${stars_response}" | grep -E '^Link' | grep -Eo 'page=[0-9]+' | tail -1 | cut -c6-); then
  echo >&2 "ERROR: Failed to determine number of starred repositories for user ${GITHUB_USER}."
  exit 1
fi
echo >&2 "Found ${STARS} starred repositories for user ${GITHUB_USER}."

if ! starred_list=$(get_starred); then
  echo >&2 "WARNING: An error was encountered while downloading list; results may be incomplete."
fi

output_filename="${GITHUB_USER}-starred-$(date '+%Y%m%d').list"
if [ -e "${output_filename}" ]; then
  echo >&2 "WARNING: Output file '${output_filename}' already exists; dumping to stdout instead..."

  # dump the entire list to stdout
  echo >&2 "Printing list..."
  echo "${starred_list}"
else
  echo >&2 "Dumping list to ${output_filename} ..."
  echo "${starred_list}" > "${output_filename}"
fi

echo >&2 "Finished dumping ${STARS} starred repositories for user ${GITHUB_USER}."
exit 0
