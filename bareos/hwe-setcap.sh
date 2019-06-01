#!/bin/bash
# Configures capabilities for Bareos LTO encryption plugin

hash /sbin/setcap 2>/dev/null || { echo >&2 "You need to install libcap2-bin. Aborting."; exit 1; }

PROG_CAPS="cap_sys_rawio+ep"

if [ ! -e "/usr/sbin/bareos-sd" ]; then
  echo >&2 "ERROR: Missing bareos-sd command: /usr/sbin/bareos-sd"
  exit 1
fi
if [ ! -e "/usr/sbin/bscrypto" ]; then
  echo >&2 "ERROR: Missing bscrypto command: /usr/sbin/bscrypto"
  exit 1
fi

function prog_getcap()
{
  local path="$1"
  if [ -z "$path" ]; then
    echo >&2 "ERROR: Path cannot be null."
    exit 1
  fi
  if [ ! -e "$path" ]; then
    echo >&2 "ERROR: Path does not exist: $path"
    exit 1
  fi

  if ! cap=$(getcap "${path}" | grep -Po '(?<=\s\=\s).*$'); then
    return 1
  fi
  if [ -z "${cap}" ]; then
    return 1
  fi

  echo "${cap}"
  return 0
}

function checkcap()
{
  local prog="$1"
  if cap=$(prog_getcap "${prog}"); then
    if [ "${cap}" != "${PROG_CAPS}" ]; then
      echo >&2 "WARNING: Unexpected program capabilities for ${prog}: ${cap} != ${PROG_CAPS}"
      return 1
    fi
  else
    echo >&2 "WARNING: Program has no special capabilities: ${prog}"
    return 1
  fi
  return 0
}

function capconfig()
{
  local prog="$1"
  if [ -z "$prog" ]; then
    echo >&2 "ERROR: Command path cannot be null."
    exit 1
  fi
  if [ ! -e "$prog" ]; then
    echo >&2 "ERROR: Program does not exist: $prog"
    exit 1
  fi

  # verify capabilities
  if ! checkcap "${prog}"; then
    # set capabilties
    echo "Calling setcap for '${prog}' ..."
    if ! /sbin/setcap "${PROG_CAPS}" "${prog}"; then
      echo >&2 "ERROR: Failed to call /sbin/setcap for ${prog}"
      return 1
    fi

    echo "Verifying capabilities for '${prog}' ..."
    if ! /sbin/setcap -v "${PROG_CAPS}" "${prog}"; then
      echo >&2 "ERROR: Failed to call /sbin/setcap for ${prog} verification."
      return 1
    fi
  fi
  return 0
}

failed=0
if ! capconfig "/usr/sbin/bareos-sd"; then
  failed=1
fi
if ! capconfig "/usr/sbin/bscrypto"; then
  failed=1
fi

exit $failed
