#!/bin/bash
# First-time Git environment setup

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

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
        echo
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

    Configures Git settings for the current user.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS

     -n, --full-name <arg>  Specify the user's full name.
     -e, --email <arg>      Specify the user's e-mail address.

     --no-install           Do not install missing diff support packages.

     -f, --force            Overwrite existing user configuration.
     -v, --verbose          Make the script more verbose.
     -h, --help             Prints this usage.

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

test_email_arg()
{
  # test user argument
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  # regex borrowed from https://emailregex.com/
  re='(?:[a-z0-9!#$%&'"'"'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"'"'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'
  if ! echo "$argv" | grep -Poq "$re"; then
    usage "Invalid e-mail address: ${argv}"
  fi
}

NO_INSTALL=0
FORCE="false"
VERBOSITY=0

VERBOSE=""
check_verbose()
{
  if [ $VERBOSITY -gt 1 ]; then
    VERBOSE="-v"
  fi
}

# process arguments
#[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--full-name)
      test_arg "$1" "$2"
      shift
      USER_FULLNAME="$1"
      shift
    ;;
    -e|--email)
      test_email_arg "$1" "$2"
      shift
      USER_EMAIL="$1"
      shift
    ;;
    -f|--force)
      FORCE="true"
      shift
    ;;
    --no-install)
      NO_INSTALL=1
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
    -h|--help)
      usage
    ;;
    *)
      # unknown option
      shift
    ;;
  esac
done

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
ROOT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

if [[ "$VERBOSITY" -gt 1 ]]; then
  echo "Resolved script directory: $ROOT_DIR"
fi

if [ -e "$HOME/.gitconfig" ] && [ "${FORCE}" != "true" ]; then
  echo >&2 "WARNING: '$HOME/.gitconfig' already exists and will not be modified."
else
  if [ -e "$HOME/.gitconfig" ]; then
    echo >&2 "WARNING: '$HOME/.gitconfig' already exists; creating backup ..."
    cp ${VERBOSE} "$HOME/.gitconfig" "$HOME/.gitconfig.backup-$(date '+%Y%m%d')"
  fi

  echo "Installing .gitconfig ..."
  cp ${VERBOSE} "${ROOT_DIR}/gitconfig.template" "${HOME}/.gitconfig"

  err=0
  if [ -z "${USER_FULLNAME}" ]; then
    USER_FULLNAME=$(getent passwd "$USER" | cut -d ':' -f 5 | cut -d ',' -f 1)
  fi
  if [ -z "${USER_FULLNAME}" ]; then
    USER_FULLNAME="${USER}"
  fi
  if [ -n "${USER_FULLNAME}" ]; then
    if ! git config --global user.name "${USER_FULLNAME}"; then
      err=1; echo >&2 "WARNING: Failed to set global user name."
    fi
  else
    err=1; echo >&2 "WARNING: Failed to determine current user's name; cannot configure user.name property."
  fi

  if [ -z "${USER_EMAIL}" ]; then
    if ! USER_DOMAIN=$(hostname -d); then
      echo >&2 "ERROR: Local hostname does not appear to have a configured domain name (hostname -d)."
    fi
    if [ -n "${USER_DOMAIN}" ]; then
      USER_EMAIL="${USER}@${USER_DOMAIN}"
      if ! git config --global user.email "${USER_EMAIL}"; then
        err=1; echo >&2 "WARNING: Failed to set global user email."
      fi
    else
      err=1; echo >&2 "WARNING: Failed to determine local domain name; cannot configure user e-mail."
    fi
  else
    if ! git config --global user.email "${USER_EMAIL}"; then
      err=1; echo >&2 "WARNING: Failed to set global user email."
    fi
  fi

  if [ "${err}" -ne 1 ]; then
    echo "Configured global Git identity: user.name='${USER_FULLNAME}', user.email='${USER_EMAIL}'"
  else
    err=0; echo >&2 "WARNING: Failed to configure one or more user properties in ~/.gitconfig file."
  fi
fi
if [ -e "$HOME/.gitattributes" ] && [ "${FORCE}" != "true" ]; then
  echo >&2 "WARNING: '$HOME/.gitattributes' already exists and will not be modified."
else
  if [ -e "$HOME/.gitattributes" ]; then
    echo >&2 "WARNING: '$HOME/.gitattributes' already exists; creating backup ..."
    cp ${VERBOSE} "$HOME/.gitattributes" "$HOME/.gitattributes.backup-$(date '+%Y%m%d')"
  fi

  echo "Installing .gitattributes ..."
  cp ${VERBOSE} "${ROOT_DIR}/gitattributes.template" "${HOME}/.gitattributes"
fi

# Check for missing diff support
declare -a missing=();
function add_missing()
{
  if [ -z "$1" ]; then
    echo >&2 "ERROR: Package name cannot be null."
    exit 1
  fi
  package_name="$1"
  missing=("${missing[@]}" "${package_name}")
  echo >&2 "WARNING: Package '${package_name}' is required for full extended diff support."
}

if ! hash pdfinfo 2>/dev/null; then
  add_missing "poppler-utils"
fi
if ! hash pandoc 2>/dev/null; then
  add_missing "pandoc"
fi
if ! hash hexdump 2>/dev/null; then
  add_missing "bsdmainutils"
fi
if ! hash odt2txt 2>/dev/null; then
  add_missing "odt2txt"
fi
if ! hash tar 2>/dev/null; then
  add_missing "tar"
fi
if ! hash xzcat 2>/dev/null; then
  add_missing "xz-utils"
fi
if ! hash bzcat 2>/dev/null; then
  add_missing "bzip2"
fi
if ! hash zcat 2>/dev/null; then
  add_missing "gzip"
fi
if ! hash unzip 2>/dev/null; then
  add_missing "unzip"
fi
if ! hash exif 2>/dev/null; then
  add_missing "exif"
fi

# Print out mappings
packages=""
for ((idx=0;idx<=$((${#missing[@]}-1));idx++)); do
  pkg="${missing[$idx]}"
  if [ $idx -gt 0 ]; then
    packages="${packages} $pkg"
  else
    packages="${pkg}"
  fi
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo "Found ${#missing[@]} missing package(s)."

  if [ "${NO_INSTALL}" == "1" ]; then
    echo "INFO: Skipped installing packages for extended diff support."
    echo "To install missing packages using apt, run:"
    echo "sudo apt install ${packages}"
    exit 0
  fi

  # See if apt-get is available
  if hash apt 2>/dev/null; then
    # Ensure sudo privileges for the current user if not running as root.
    echo "Validating permissions for user $USER ..."
    if [[ $EUID -ne 0 ]]; then
      echo "NOTICE: Running as user $USER; sudo privileges required."
      hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }
      if ! sudo echo "" > /dev/null 2>&1; then
        echo >&2 "ERROR: Must have sudo privileges to modify configuration files."
        exit 1
      fi
    fi

    echo "Attempting to install: $packages ..."
    apt_command="sudo apt install $packages"
    if ! ${apt_command}; then
      echo >&2 "ERROR: Failed to install missing packages."
      exit 1
    fi
  else
    echo "WARNING: Could not install missing packages for extended diff support."
    echo "To install missing packages using apt, run:"
    echo "sudo apt install ${packages}"
  fi
fi

exit 0
