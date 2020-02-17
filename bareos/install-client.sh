#!/bin/bash
#
# [ 0x19e Networks ]
# Author: Robert W. Baumgartner <rwb@0x19e.net>
#
# install-client.sh : Install Bareos FileDaemon (client)
#
# NOTE: This script currently supports only APT on Debian and Debian-based distributions (ie. Ubuntu).

hash grep 2>/dev/null || { echo >&2 "You need to install grep. Aborting."; exit 1; }
hash awk 2>/dev/null || { echo >&2 "You need to install awk. Aborting."; exit 1; }
hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }
hash wget 2>/dev/null || { echo >&2 "You need to install wget. Aborting."; exit 1; }
hash /usr/bin/gpg 2>/dev/null || { echo >&2 "You need to install gnupg. Aborting."; exit 1; }
hash apt 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }
hash tee 2>/dev/null || { echo >&2 "You need to install tee. Aborting."; exit 1; }
hash lsb_release 2>/dev/null || { echo >&2 "You need to install lsb-release. Aborting."; exit 1; }

# Set script default verbosity
VERBOSITY=0

# Get distro release version
UBUNTU_RELEASE=$(lsb_release -a 2>/dev/null | grep Release | awk '{print $2}')

# Configure the package name
PKGNAME="bareos-filedaemon"

# Configure remote package source
HTPROTO="http"
KEYNAME="Release.key"
SRC_PKG="xUbuntu_${UBUNTU_RELEASE}"
SRC_URL="download.bareos.org/bareos/release/latest"

# Configure package source installation
APT_DIR="/etc/apt/sources.list.d"
PKG_LST="${APT_DIR}/bareos.list"

# Configure apt arguments
APT_ARG="--verbose-versions --yes"

# Uncomment to enable /etc source control Git handling
ETCKEEPER_COMMIT="true"

# Update the signing key regardless of whether or not its installed
UPDATE_KEY="false"

# Uncomment to run script when the package is already installed
#FORCE_INSTALL="true"

function check_installed()
{
  pkg_name="$1"
  if [ -z "${pkg_name}" ]; then
    echo >&2 "ERROR: Package name not provided to check script."
    exit 1
  fi

  if hash apt-cache 2>/dev/null; then
    if apt-cache policy "${pkg_name}" | grep -v '(none)' | grep -q Installed; then
      return 0
    fi
  fi

  return 1
}

function is_valid_protocol()
{
  proto_name="$1"
  if [ -z "${proto_name}" ]; then
    echo >&2 "No protocol string was specified."
    exit 1
  fi

  if echo "${proto_name}" | grep -qE '^[Hh][Tt][Tt][Pp]([Ss])?$'; then
    return 0
  fi

  echo >&2 "ERROR: Invalid HTTP protocol '${proto_name}'."
  return 1
}

function is_https()
{
  proto_name="$1"
  if [ -z "${proto_name}" ]; then
    echo >&2 "No protocol string was specified."
    exit 1
  fi

  if echo "${proto_name}" | grep -qE '^[Hh][Tt][Tt][Pp][Ss]$'; then
    # https protocol
    return 0
  fi

  # http protocol
  return 1
}

function valid_url()
{
  url="$1"
  if [ -z "${url}" ]; then
    echo >&2 "No URL string was specified."
    exit 1
  fi

  if wget -q "${url}" -O /dev/null; then
    return 0
  fi

  return 1
}

check_url()
{
  url="$1"
  if [ -z "${url}" ]; then
    echo >&2 "No URL string was specified."
    exit 1
  fi

  if ! valid_url "${url}"; then
    echo >&2 "ERROR: Invalid URL: '${url}'"
    exit 1
  fi
}

check_protocol()
{
  proto_name="$1"
  if [ -z "${proto_name}" ]; then
    echo >&2 "No protocol string was specified."
    exit 1
  fi

  if ! is_valid_protocol "$proto_name"; then
    exit 1
  fi

  if is_https "$proto_name"; then
    if hash apt 2>/dev/null; then
      if ! check_installed "apt-transport-https"; then
        echo >&2 "ERROR: Must install apt-transport-https for HTTPS protocol support."
        exit 1
      fi
    fi
  fi
}

check_etckeeper()
{
  # git handling for etckeeper (check if /etc/.git exists)
  if [ -d /etc/.git  ] && hash git 2>/dev/null; then
    if sudo git -C "/etc" rev-parse > /dev/null 2>&1; then
      # check /etc/apt for modifications
      # if there are changes, commit them
      if [[ "$(sudo git --git-dir=/etc/.git --work-tree=/etc status --porcelain -- /etc/apt | grep -E '^(M| M)')" != "" ]]; then
        if [ "${ETCKEEPER_COMMIT}" != "true" ]; then
          echo >&2 "WARNING: Uncommitted changes under version control: /etc/apt"
          echo >&2 "WARNING: You may want to enable automatic handling with --enable-etckeeper"
          return
        fi
        echo "Auto-commit changes to /etc/apt (directory under version control) ..."
        pushd /etc > /dev/null 2>&1 || return
        sudo git add --all /etc/apt
        sudo git commit -v -m "apt: add bareos package source"
        popd > /dev/null 2>&1 || return
      fi
    fi
  fi
}

install_key_from_url()
{
  key_url="$1"
  if [ -z "${key_url}" ]; then
    echo >&2 "No key URL was specified."
    exit 1
  fi

  # check if the key is already installed
  echo "Downloading release signing key from '${key_url}' ..."
  KEY_RW=$(wget -qO - "${key_url}")
  if [ -z "${KEY_RW}" ]; then
    echo >&2 "Failed to retrieve signing key from ${key_url}"
    exit 1
  fi
  if ! echo "${KEY_RW}" | /usr/bin/gpg --list-packets > /dev/null 2>&1; then
    echo >&2 "Invalid key returned from URL ${key_url}"
    exit 1
  fi

  GPG_RW=$(echo "${KEY_RW}" | /usr/bin/gpg --with-fingerprint --keyid-format SHORT 2>/dev/null | grep -P '^pub' | head -n1)

  # Get key name
  KEY_ID=$(echo "${GPG_RW}" | cut -d' ' -f5- | awk '{$1=$1};1')

  # Get key size/fingerprint
  KEY_TP=$(echo "${GPG_RW}" | awk '{ print $2 }' | awk '{$1=$1};1')

  # Get key size and type
  KEY_SZ=$(echo "${KEY_TP}" | cut -d/ -f1)

  # Get key fingerprint
  KEY_FP=$(echo "${KEY_TP}" | cut -d/ -f2)

  echo "Found signing key  : ${KEY_ID}"
  if [ $VERBOSITY -gt 0 ]; then
  echo "Key fingerprint    : ${KEY_FP}"
  echo "Key size and type  : ${KEY_SZ}"
  fi

  KEY_LIST=$(apt-key list --keyid-format SHORT 2>/dev/null)
  if echo "${KEY_LIST}" | grep "${KEY_FP}" > /dev/null 2>&1; then
    echo "Key '${KEY_ID}' (${KEY_TP}) is already installed."
    return
  fi

  # add the release key
  echo "Installing '${KEY_ID}' (${KEY_TP}) ..."

  if ! echo "${KEY_RW}" | sudo apt-key add -; then
    exit 1
  fi
}

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

    Installs the Bareos Filedaemon client daemon on the current host.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS
     -p, --protocol <http>       The protocol to use. Either http or https.
     -r, --release <full-name>   The full name of the platform release.

     --update-key                Update the GnuPG signing key and exit.
     --no-etckeeper              Do not commit VCS changes under /etc

     -f, --force                 Force re-installation.
     -v, --verbose               Make the script more verbose.
     -h, --help                  Prints this usage.

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

test_proto_arg()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  if ! is_valid_protocol "$argv"; then
    usage "Invalid protocol specified: '$argv' (must be http or https)"
  fi
}

# process arguments
#[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -r|--release)
      test_arg "$1" "$2"
      shift
      export SRC_PKG="$1"
      shift
    ;;
    -p|--protocol)
      test_proto_arg "$1" "$2"
      shift
      export HTPROTO="$1"
      shift
    ;;
    -k|--key-name)
      test_arg "$1" "$2"
      shift
      export KEYNAME="$1"
      shift
    ;;
    -f|--force)
      export FORCE_INSTALL="true"
      shift
    ;;
    --update-key)
      export UPDATE_KEY="true"
      shift
    ;;
    --no-etckeeper)
      export ETCKEEPER_COMMIT="false"
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      shift
    ;;
    -vv)
      ((VERBOSITY++))
      ((VERBOSITY++))
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      # unknown option
      usage "Unknown option: ${1}."
    ;;
  esac
done

# check base repository url
if [ -z "${SRC_URL}" ]; then
  usage "Missing public-key filename."
fi
# check platform release name
if [ -z "${SRC_PKG}" ]; then
  usage "Missing release identifier."
fi
# check key filename
if [ -z "${KEYNAME}" ]; then
  usage "Missing public-key filename."
fi

# Configure some variables
PKG_SRC="${SRC_URL}/${SRC_PKG}"
PKG_KEY="${SRC_URL}/${SRC_PKG}/${KEYNAME}"

# check repository url
if [ -z "${PKG_SRC}" ]; then
  usage "Missing package repository base URL."
fi
# check public-key url
if [ -z "${PKG_KEY}" ]; then
  usage "Missing public-key URL."
fi

# Configure full variables
PKG_URL="${HTPROTO}://${PKG_SRC}"
KEY_URL="${HTPROTO}://${PKG_KEY}"
DEB_TXT="deb ${PKG_URL} ./"

# Check required settings
if [ -z "${UBUNTU_RELEASE}" ]; then
  echo >&2 "ERROR: Unable to determine Ubuntu release."
  exit 1
fi
if [ -z "${PKGNAME}" ]; then
  echo >&2 "ERROR: Unable to determine package name."
  exit 1
fi

# Validate package source settings
check_protocol "${HTPROTO}"
check_url      "${PKG_URL}"
check_url      "${KEY_URL}"

# check if the package is already installed
if [ "${FORCE_INSTALL}" != "true" ] && check_installed "${PKGNAME}"; then
  if [ "${UPDATE_KEY}" == "true" ]; then
    # install signing key and exit
    install_key_from_url "${KEY_URL}"
    check_etckeeper
    exit_script 0
  fi

  exit_script 0 "The package '${PKGNAME}' is already installed."
fi

echo "Installing Bareos FileDaemon backup client for Ubuntu ${UBUNTU_RELEASE} ..."

# install signing key
install_key_from_url "${KEY_URL}"

if [ "${UPDATE_KEY}" == "true" ]; then
  # check if /etc is under version control
  check_etckeeper
  exit $?
fi

if [ $VERBOSITY -gt 0 ]; then
# print some details about source configuration
echo "Configuration file : ${PKG_LST}"
echo "Package repository : ${PKG_URL}"
fi

# add the package source if not already configured
CUR_CFG=$(grep -RF "${PKG_SRC}" "${APT_DIR}/" 2>/dev/null | grep -v '\#' | head -n1 | cut -d: -f1)
if [ -n "${CUR_CFG}" ] && [ ! -e "${CUR_CFG}" ]; then
  echo >&2 "ERROR: Something went wrong while looking for source configuration."
  exit 1
fi

# add source if no existing configuration was found
if [ -z "${CUR_CFG}" ]; then
  echo "Configure missing package source ..."
  if ! echo "${DEB_TXT}" | sudo tee -a "${PKG_LST}"; then
    exit 1
  fi

  # update the package cache
  echo "Updating package list ..."
  if ! sudo apt update > /dev/null 2>&1; then
    exit 1
  fi
fi

# check if /etc is under version control
check_etckeeper

# install the actual package
echo "Installing package : ${PKGNAME} ..."
install_cmd="sudo apt ${APT_ARG}"
if ! ${install_cmd} install ${PKGNAME}; then
  echo >&2 "ERROR: Failed to install Bareos client."
  exit 1
fi

echo "Bareos FileDaemon (${PKGNAME}) installation successful."
exit_script 0
