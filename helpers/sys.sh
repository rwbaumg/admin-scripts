#!/usr/bin/env bash
# General system helpers

# Compare version numbers
#
# Usage:
#    if version_gt "$VERSION" "$MIN_VERSION"; then ...
#
function version_gt() { test "$(printf '%s\n' "$@" | sort -bt. -k1,1 -k2,2n -k3,3n -k4,4n -k5,5n | head -n 1)" != "$1"; }

# Execute a command as root (or sudo)
function do_with_root()
{
    # already root? "Just do it" (tm).
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

# get the root directory this script is running from
# if the script is called from a symlink, the link is
# resolved to the absolute path.
function get_root_dir() {
  source="${BASH_SOURCE[0]}"
  # resolve $source until the file is no longer a symlink
  while [ -h "${source}" ]; do
    dir=$( cd -P "$( dirname "${source}" )" && pwd )
    source=$(readlink "${source}")
    # if $source was a relative symlink, we need to resolve it
    # relative to the path where the symlink file was located
    [[ ${source} != /* ]] && source="${dir}/${source}"
  done
  dir="$( cd -P "$( dirname "${source}" )" && pwd )"
  echo "${dir}"
  return
}

function is_number() {
  if [ -z "${1}" ]; then
    return 1
  fi

  re='^[0-9]+$'
  if [[ ${1} =~ $re ]]; then
    return 0
  fi

  return 1
}

function prog_getcap() {
  hash /sbin/setcap 2>/dev/null || { echo >&2 "You need to install libcap2-bin. Aborting."; exit 1; }

  local path="$1"
  if [ -z "$path" ]; then
    echo >&2 "ERROR: Path cannot be null."
    exit 1
  fi
  if [ ! -e "$path" ]; then
    echo >&2 "ERROR: Path does not exist: $path"
    exit 1
  fi

  if ! cap=$(/sbin/getcap "${path}" | grep -Po '(?<=\s\=\s).*$'); then
    return 1
  fi
  if [ -z "${cap}" ]; then
    return 1
  fi

  echo "${cap}"
  return 0
}

function checkcap() {
  hash /sbin/setcap 2>/dev/null || { echo >&2 "You need to install libcap2-bin. Aborting."; exit 1; }

  local prog, caps
  prog="$1"
  caps="$2"

  if [ -z "$prog" ]; then
    echo >&2 "ERROR: Command path cannot be null."
    exit 1
  fi
  if [ -z "$caps" ]; then
    echo >&2 "ERROR: Capability string cannot be null."
    exit 1
  fi

  if cap=$(prog_getcap "${prog}"); then
    if [ "${cap}" != "${caps}" ]; then
      echo >&2 "WARNING: Unexpected program capabilities for ${prog}: ${cap} != ${caps}"
      return 1
    fi
  else
    echo >&2 "WARNING: Program has no special capabilities: ${prog}"
    return 1
  fi
  return 0
}

function capconfig() {
  hash /sbin/setcap 2>/dev/null || { echo >&2 "You need to install libcap2-bin. Aborting."; exit 1; }

  local prog, caps
  prog="$1"
  caps="$2"

  if [ -z "$prog" ]; then
    echo >&2 "ERROR: Command path cannot be null."
    exit 1
  fi
  if [ -z "$caps" ]; then
    echo >&2 "ERROR: Capability string cannot be null."
    exit 1
  fi
  if [ ! -e "$prog" ]; then
    echo >&2 "ERROR: Program does not exist: $prog"
    exit 1
  fi

  # verify capabilities
  if ! checkcap "${prog}" "${caps}"; then
    # set capabilties
    echo "Calling setcap('${caps}') for '${prog}' ..."
    if ! /sbin/setcap "${caps}" "${prog}"; then
      echo >&2 "ERROR: Failed to call /sbin/setcap for ${prog}"
      return 1
    fi

    echo "Verifying capabilities '${caps}' for '${prog}' ..."
    if ! /sbin/setcap -v "${caps}" "${prog}"; then
      echo >&2 "ERROR: Failed to call /sbin/setcap for ${prog} verification."
      return 1
    fi
  fi
  return 0
}
