#!/bin/bash
#
# [ 0x19e Networks ]
# Author: Robert W. Baumgartner <rwb@0x19e.net>
#
# install-munin.sh : Install Munin monitoring.
#
# Munin Installation Guide:
#   http://guide.munin-monitring.org/en/latest/installation/install.html
#
# NOTE: This script currently supports only APT on Debian and Debian-based distributions (ie. Ubuntu).

hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }
hash apt 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }
hash lsb_release 2>/dev/null || { echo >&2 "You need to install lsb-release. Aborting."; exit 1; }
hash gpg 2>/dev/null || { echo >&2 "You need to install gnupg. Aborting."; exit 1; }
#hash grep 2>/dev/null || { echo >&2 "You need to install grep. Aborting."; exit 1; }
#hash awk 2>/dev/null || { echo >&2 "You need to install awk. Aborting."; exit 1; }
#hash wget 2>/dev/null || { echo >&2 "You need to install wget. Aborting."; exit 1; }
#hash tee 2>/dev/null || { echo >&2 "You need to install tee. Aborting."; exit 1; }

# Set script default verbosity
VERBOSITY=0

# Get distro release version
UBUNTU_RELEASE=$(lsb_release -a 2>/dev/null | grep Release | awk '{print $2}')

# Configure the package name
PKGNAME_CLIENT="munin-node munin-plugins-core munin-plugins-extra"
PKGNAME_SERVER="munin"
PKGNAME_TESTPK="munin-common"

# Variable to control server installation.
INSTALL_SERVER="false"

# Configure remote package source
HTPROTO="http"
KEYNAME="Release.key"

#PKG_NAME="munin"
#SRC_PKG="xUbuntu_${UBUNTU_RELEASE}"
#SRC_URL="download.example.come/release/latest"

# Configure package source installation
#APT_DIR="/etc/apt/sources.list.d"
#PKG_LST="${APT_DIR}/${PKG_NAME}.list"

# Configure apt arguments
APT_ARG="--verbose-versions --yes"

# Uncomment to enable /etc source control Git handling
ETCKEEPER_COMMIT="true"

# Update the signing key regardless of whether or not its installed
#UPDATE_KEY="false"

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
  if [ -z "${pkg_name}" ]; then
    echo >&2 "WARNING: Package name is undefined; skipping etckeeper handling."
  fi
  if [[ $EUID -ne 0 ]]; then
    echo >&2 "WARNING: Must run as root to commit /etc changes."
    return
  fi
  if [ ! -e "/etc/${pkg_name}" ]; then
    echo >&2 "WARNING: The folder /etc/${pkg_name} does not exist."
    return
  fi

  # git handling for etckeeper (check if /etc/.git exists)
  if [ -d /etc/.git  ] && hash git 2>/dev/null; then
    if git -C "/etc" rev-parse > /dev/null 2>&1; then
      # check /etc/apt for modifications
      # if there are changes, commit them
      if [[ "$(git --git-dir=/etc/.git --work-tree=/etc status --porcelain -- "/etc/${pkg_name}" | grep -E '^(M| M)')" != "" ]]; then
        if [ "${ETCKEEPER_COMMIT}" != "true" ]; then
          echo >&2 "WARNING: Uncommitted changes under version control: /etc/apt"
          echo >&2 "WARNING: You may want to enable automatic handling with --enable-etckeeper"
          return
        fi
        echo "Auto-commit changes to /etc/apt (directory under version control) ..."
        pushd /etc > /dev/null 2>&1
        sudo git add --all /etc/apt
        sudo git commit -v -m "apt: add ${pkg_name} package source"
        popd > /dev/null 2>&1
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
  KEY_RW=$(wget -qO - "${key_url}")
  if [ -z "${KEY_RW}" ]; then
    echo >&2 "Failed to retrieve signing key from ${key_url}"
    exit 1
  fi
  if ! echo "${KEY_RW}" | gpg --list-packets > /dev/null 2>&1; then
    echo >&2 "Invalid key returned from URL ${key_url}"
    exit 1
  fi

  GPG_RW=$(echo "${KEY_RW}" | gpg --with-fingerprint --keyid-format SHORT 2>/dev/null | grep -P '^pub' | head -n1)
  KEY_ID=$(echo "${GPG_RW}" | cut -d' ' -f5- | awk '{$1=$1};1')

  KEY_TP=$(echo "${GPG_RW}" | awk '{ print $2 }' | awk '{$1=$1};1')
  KEY_SZ=$(echo "${KEY_TP}" | cut -d/ -f1)
  KEY_FP=$(echo "${KEY_TP}" | cut -d/ -f2)

  KEY_LIST=$(apt-key list --keyid-format SHORT 2>/dev/null)
  if echo "${KEY_LIST}" | grep "${KEY_FP}" > /dev/null 2>&1; then
    echo "Found signing key  : ${KEY_ID}"
    if [ $VERBOSITY -gt 0 ]; then
    echo "Key fingerprint    : ${KEY_FP}"
    echo "Key size and type  : ${KEY_SZ}"
    fi
    return
  fi

  # add the release key
  echo "Retrieve signing key from ${key_url} ..."

  if [ $VERBOSITY -gt 0 ]; then
  echo "Key identifier     : ${KEY_ID}"
  echo "Key fingerprint    : ${KEY_FP}"
  echo "Key size and type  : ${KEY_SZ}"
  fi

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

    Installs the Munin monitoring package on the current host.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS
     -s, --server                Install the Munin server.

     --no-etckeeper              Do not commit VCS changes under /etc

     -f, --force                 Force re-installation.
     -v, --verbose               Make the script more verbose.
     -h, --help                  Prints this usage.

EOF

    exit_script "$@"
}

#     -p, --protocol <http>       The protocol to use. Either http or https.
#     -r, --release <full-name>   The full name of the platform release.
#
#     --update-key                Update the GnuPG signing key and exit.

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
    -s|--server)
      export INSTALL_SERVER="true"
      shift
    ;;
#    --update-key)
#      export UPDATE_KEY="true"
#      shift
#    ;;
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

# Check required settings
if [ -z "${UBUNTU_RELEASE}" ]; then
  echo >&2 "ERROR: Unable to determine Ubuntu release."
  exit 1
fi

# check if the package is already installed
if [ "${FORCE_INSTALL}" != "true" ] && check_installed "${PKGNAME_TESTPK}"; then
  exit_script 0 "The package '${PKGNAME_TESTPK}' is already installed."
fi

echo "Installing Munin node for Ubuntu ${UBUNTU_RELEASE} ..."


#if [ $VERBOSITY -gt 0 ]; then
# print some details about source configuration
#echo "Configuration file : ${PKG_LST}"
#echo "Package repository : ${PKG_URL}"
#fi

# add the package source if not already configured
#CUR_CFG=$(grep -RF "${PKG_SRC}" "${APT_DIR}/" 2>/dev/null | grep -v '\#' | head -n1 | cut -d: -f1)
#if [ -n "${CUR_CFG}" ] && [ ! -e "${CUR_CFG}" ]; then
#  echo >&2 "ERROR: Something went wrong while looking for source configuration."
#  exit 1
#fi

# add source if no existing configuration was found
#if [ -z "${CUR_CFG}" ]; then
#  echo "Configure missing package source ..."
#  if ! echo "${DEB_TXT}" | sudo tee -a "${PKG_LST}"; then
#    exit 1
#  fi
#
#  # update the package cache
#  echo "Updating package list ..."
#  if ! sudo apt update > /dev/null 2>&1; then
#    exit 1
#  fi
#fi

# update the package cache
echo "Updating package list ..."
if ! sudo apt update > /dev/null 2>&1; then
  exit 1
fi

# create package list
APT_PKGS="${PKGNAME_CLIENT}"
if [ "${INSTALL_SERVER}" == "true" ]; then
  APT_PKGS="${APT_PKGS} ${PKGNAME_SERVER}"
fi


# install the actual package
echo "Installing packages : ${APT_PKGS} ..."
install_cmd="sudo apt ${APT_ARG} install ${APT_PKGS}"
if ! ${install_cmd}; then
  echo >&2 "ERROR: Installation failed."
  exit 1
fi

# check if /etc is under version control
check_etckeeper

echo "Package installation successful for ${APT_PKGS}."
exit_script 0
