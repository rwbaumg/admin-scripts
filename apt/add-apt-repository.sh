#!/bin/bash
# Alternative script to handle adding PPA sources for APT

#UBUNTU_VERSION="focal"
#UBUNTU_VERSION="devel"
UBUNTU_VERSION="bionic"

PPA_BASE_URL="http://ppa.launchpad.net"
GPG_KEYSERVER="keyserver.ubuntu.com"

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
  if echo "$@" | grep -iqE "$re"; then
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
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename "$0")|" -e "s|DEFAULT_DIST|${UBUNTU_VERSION}|" << EOF
    USAGE

    Utility to add PPA repositories to your Debian-based system.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ppa:user/ppa-name

    OPTIONS

     -d, --dist <name>     The distribution name to use.
                           Default: 'DEFAULT_DIST'

     -v, --verbose         Make the script more verbose.
     -h, --help            Prints this usage.

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

VERBOSITY=0
VERBOSE=""
check_verbose()
{
  if [ $VERBOSITY -gt 0 ]; then
    VERBOSE="-v"
  fi
}

PPA_ARG=""

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dist)
      test_arg "$1" "$2"
      shift
      UBUNTU_VERSION="$1"
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      check_verbosity
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      if [ -n "${PPA_ARG}" ]; then
        usage
      fi
      test_arg "$1"
      PPA_ARG="$1"
      shift
    ;;
  esac
done

if [ -z "${PPA_ARG}" ]; then
    usage "Must supply a PPA to add."
fi
if [ -z "${UBUNTU_VERSION}" ]; then
    usage "No distribution name specified."
fi
if [ -z "${GPG_KEYSERVER}" ]; then
    usage "No GnuPG keyserver specified."
fi

# check if superuser
if [[ $EUID -ne 0 ]]; then
    usage "This script must be run as root."
fi

if ! NAME=$( (uname -a && date) | md5sum | cut -f1 -d" " ); then
	usage "Failed to calculate package identifier."
fi

if ! echo "${PPA_ARG}" | grep -E '^ppa\:'; then
        usage "Invalid PPA identifier: '${PPA_ARG}'."
fi

ppa_name=$(echo "${PPA_ARG}" | cut -d":" -f2 -s)
if [ -z "$ppa_name" ]; then
	usage "PPA name not found."
fi

if [ ! -d "/etc/apt/sources.list.d" ]; then
        usage "Package source directory is missing: /etc/apt/sources.list.d"
fi

ppa_filename=$(echo "${ppa_name}" | sed -e 's/\//_/g')
ppa_output="/etc/apt/sources.list.d/${ppa_filename}.list"
if [ -e "${ppa_output}" ]; then
        usage "Package source '${ppa_output}' already exists."
fi
if ! temp_file=$(mktemp -t "${NAME}_apt_add_key.XXXXXXXX.txt"); then
	exit_script 1 "Failed to create temporary file."
fi

echo "Adding PPA package source: ${ppa_name} ..."
echo "deb ${PPA_BASE_URL}/${ppa_name}/ubuntu ${UBUNTU_VERSION} main" > "${ppa_output}"

function rollback_changes()
{
	if [ ! -z "${apt_trusted_backup}" ]; then
		if [ -e "${apt_trusted_backup}" ]; then
			echo >&2 "Restoring /etc/apt/trusted.gpg from backup ..."
			if ! cp ${VERBOSE} "${apt_trusted_backup}" "/etc/apt/trusted.gpg"; then
				echo >&2 "WARNING: Failed to restore /etc/apt/trusted.gpg"
			fi
			echo >&2 "Removing backup file ..."
			if ! rm ${VERBOSE} "${apt_trusted_backup}"; then
				echo >&2 "WARNING: Failed to delete backup file '${apt_trusted_backup}'."
			fi
		else
			echo >&2 "WARNING: Keys backup '${apt_trusted_backup}' does not exist."
		fi
	fi
        if [ -e "${temp_file}" ]; then
		echo >&2 "Removing temporary file ..."
                rm -r ${VERBOSE} "${temp_file}"
        fi
        if [ -e "${ppa_output}" ]; then
                rm -r ${VERBOSE} "${ppa_output}"
        fi
}

# update package repositories and log errors to temp. file
echo "Performing online check for missing package key (this might take a minute) ..."
apt-get update > /dev/null 2> "${temp_file}"

# check for and install missing keys for package signing
key=$(grep "NO_PUBKEY" "${temp_file}" | cut -d":" -f6 | cut -d" " -f3)
if [ -z "${key}" ]; then
	# Failed to find signing key for package source.
	echo >&2 "No signing key errors for package source (already installed?)."

	if [ -s "${temp_file}" ]; then
	echo >&2 "Error output from cache update:"
	cat >&2 "${temp_file}"
        rollback_changes
	exit_script 1 "Failed to update cache using package source."
	fi
else

echo "Creating backup of /etc/apt/trusted.gpg ..."
if ! apt_trusted_backup=$(mktemp -t "apt_trusted.XXXXXXXX.bak"); then
	apt_trusted_backup=""
        rollback_changes
	exit_script 1 "Failed to create temporary file."
fi
if ! cp ${VERBOSE} "/etc/apt/trusted.gpg" "${apt_trusted_backup}"; then
	apt_trusted_backup=""
        rollback_changes
	exit_script 1 "Failed to create backup of /etc/apt/trusted.gpg."
fi

echo "Downloading PPA key from ${GPG_KEYSERVER} (key id: $key) ..."
if ! apt-key adv --keyserver "${GPG_KEYSERVER}" --recv-keys "$key"; then
        rollback_changes
	exit_script 1 "Failed to retrieve PPA signing key."
fi

echo "Updating package cache ..."
if ! apt-get update; then
        rollback_changes
	exit_script 1 "Failed to install PPA: ${ppa_name}"
fi

if [ -e "${ppa_output}" ]; then
    echo >&2 "Removing backup file ..."
    rm -r ${VERBOSE} "${apt_trusted_backup}"
fi

fi

if [ -e "${temp_file}" ]; then
    echo >&2 "Removing temporary file ..."
    rm -r ${VERBOSE} "${temp_file}"
fi

echo "Finished."
exit 0
