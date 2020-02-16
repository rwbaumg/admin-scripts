#!/bin/bash
# Configure system skeleton for new users

SCRIPT_PATH=$(dirname "$0")

ETCKEEPER_COMMIT="true"
FORCE_INSTALL="false"

SYS_SKEL_PATH="/etc/skel"
GPG_SKEL_PATH="${SYS_SKEL_PATH}/.gnupg"

CFG_REPO_PATH="${SCRIPT_PATH}/configs"
GNUPG_CONFIGS="${CFG_REPO_PATH}/gnupg"

function exit_script()
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

function usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename "$0")|" << EOF
    USAGE

    Configures user configuration skeleton. Requires root.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS
     --no-gnupg                  Do not include GnuPG skeleton.
     --no-etckeeper              Do not auto-commit /etc changes under VCS.

     -f, --force                 Force re-installation.
     -v, --verbose               Make the script more verbose.
     -h, --help                  Prints this usage.

EOF

    exit_script "$@"
}

function test_arg()
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

function require_root() {
  # check if superuser
  if [[ $EUID -ne 0 ]]; then
    echo >&2 "This script must be run as root."
    exit 1
  fi
}

function do_with_root() {
  if [[ $(whoami) = 'root' ]]; then
    bash -c "$@"
  elif [[ -x /bin/sudo || -x /usr/bin/sudo ]]; then
    echo "sudo $*"
    sudo bash -c "$@"
  else
    echo "This script must be run as root." >&2
    exit 1
  fi
}

function check_etckeeper()
{
  if [[ $EUID -ne 0 ]]; then
    echo >&2 "WARNING: Must run as root to commit /etc changes."
    return 1
  fi
  if [ ! -e "${SYS_SKEL_PATH}" ]; then
    echo >&2 "WARNING: The folder ${SYS_SKEL_PATH} does not exist."
    return 1
  fi

  # git handling for etckeeper (check if /etc/.git exists)
  if [ -d /etc/.git  ] && hash git 2>/dev/null; then
    if git -C "/etc" rev-parse > /dev/null 2>&1; then
      # check /etc/apt for modifications
      # if there are changes, commit them
      if [[ "$(git --git-dir=/etc/.git --work-tree=/etc status --porcelain -- "${SYS_SKEL_PATH}" | grep -E '^(M| M)')" != "" ]]; then
        if [ "${ETCKEEPER_COMMIT}" != "true" ]; then
          echo >&2 "WARNING: Uncommitted changes under version control: ${SYS_SKEL_PATH}"
          echo >&2 "WARNING: You may want to enable automatic handling with --enable-etckeeper"
          return 1
        fi
        echo "Auto-commit changes to ${SYS_SKEL_PATH} (directory under version control) ..."
        err=0
        pushd /etc > /dev/null 2>&1
        if ! git add --all "${SYS_SKEL_PATH}"; then
          err=1
        fi
        if ! git commit -v -m "skel: auto-commit updated configurations."; then
          err=1
        fi
        popd > /dev/null 2>&1
        return "$err"
      fi
    fi
  fi

  return 0
}

function install_gpg_skel() {
  if [ -z "$1" ]; then
    echo >&2 "Path cannot be null."
    exit 1
  fi

  skel_path="$1"
  if [ -e "${skel_path}" ] && [ "${FORCE_INSTALL}" != "true" ]; then
    echo >&2 "WARNING: Skeleton path already exists: '${skel_path}'"
    return
  fi

  echo "Installing GnuPG skeleton to '${skel_path}' ..."
  if [ ! -e "${skel_path}" ]; then
    do_with_root "mkdir -v -m 700 '${skel_path}'"
  fi
  do_with_root "chmod 700 '${skel_path}'"

  find "${GNUPG_CONFIGS}" -type f -name "*.example" | while read -r example_cfg; do
    cfg_name="$(basename "${example_cfg%.*}")"
    if ! do_with_root "cp -v '${example_cfg}' '${skel_path}/${cfg_name}'"; then
      echo >&2 "ERROR: Failed to copy configuration template '${example_cfg}' to skeleton."
      exit 1
    fi
  done

  return 0
}

declare -a gpg_paths=();
function add_gpg_path()
{
  if [ -z "$1" ]; then
    echo >&2 "Path cannot be null."
    exit 1
  fi
  if ! echo "${gpg_paths[@]}" | grep -q -w "$1"; then
    gpg_path="$1"
    gpg_paths=("${gpg_paths[@]}" "${gpg_path}")
  fi
}

function install_gpg_pkg_skel() {
  if hash gpg2 2>/dev/null; then
    add_gpg_path "/usr/share/gnupg2"
  fi
  if hash gpg 2>/dev/null; then
    add_gpg_path "/usr/share/gnupg"
  fi

  err=0
  if [[ ${#gpg_paths[@]} -ge 1 ]]; then
    for ((idx=0;idx<=$((${#gpg_paths[@]}-1));idx++)); do
      gpg_path="${gpg_paths[$idx]}"
      echo "Configuring GnuPG skeleton directory: ${gpg_path} ..."
      if ! install_gpg_skel "${gpg_path}"; then
        err=1; echo >&2 "ERROR: Failed to configure skeleton for '${gpg_path}'."
      fi
    done
  else
    echo >&2 "WARNING: GnuPG is not installed; will not install skeleton."
  fi

  if [ "$err" -ne 0 ]; then
    return 1
  fi

  return 0
}

### Process arguments

VERBOSITY=0
VERBOSE="-v"
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
    -f|--force)
      export FORCE_INSTALL="true"
      shift
    ;;
    --no-etckeeper)
      export ETCKEEPER_COMMIT="false"
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
      usage "Unknown option: ${1}."
    ;;
  esac
done

### Perform configuration

# Require root permission
require_root

# Install base configurations
# TODO: Check for/handle existing files
CP_CMD="cp ${VERBOSE}"
${CP_CMD} "${CFG_REPO_PATH}/bash.aliases" "${SYS_SKEL_PATH}/.bash_aliases"
${CP_CMD} "${CFG_REPO_PATH}/bash.logout" "${SYS_SKEL_PATH}/.bash_logout"
${CP_CMD} "${CFG_REPO_PATH}/bashrc.example" "${SYS_SKEL_PATH}/.bashrc"
${CP_CMD} "${CFG_REPO_PATH}/profile.skel" "${SYS_SKEL_PATH}/.profile"

# (Optional) Extra configurations
# cp -v "${CFG_REPO_PATH}/nanorc.example" "${SYS_SKEL_PATH}/.nanorc.example"

# Install system GnuPG skeleton
if ! install_gpg_skel "${GPG_SKEL_PATH}"; then
  echo >&2 "ERROR: Failed to install user GnuPG skeleton."
fi
if ! install_gpg_pkg_skel; then
  echo >&2 "ERROR: Failed to install system GnuPG skeleton."
fi

# Ensure correct permissions
do_with_root "chmod -v 700 ""${SYS_SKEL_PATH}"""

# Check if /etc is under VCS
if ! check_etckeeper; then
  exit_script 1 "Failed to auto-commit /etc changes under version control."
fi

echo "Finished configuring user skeleton '${SYS_SKEL_PATH}'."
exit_script 0
