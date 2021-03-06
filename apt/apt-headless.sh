#!/bin/bash
# Runs an apt operation without any user-interaction.
# Note: The options below are dangerous!
# APT_ARGS='--allow-remove-essential --allow-downgrades --allow-change-held-packages'

# Set preference for configuration file handling ('new' or 'old')
CONFIG_PREF="new"
#CONFIG_PREF="old"

# Set Bash environment
BASH_ENV="DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none"

# Configure base APT command
APT_CMD="dist-upgrade"

# Configure apt options
APT_ARGS="--yes"

# COnfigure Dpkg options
DPKG_OPTS=("--force-confdef" "--force-conf${CONFIG_PREF}")

# Configure command prefix
PRE_CMD=""

## Validate
if [ ! -z "$1" ]; then
  APT_CMD="$1"
fi
if [ -z "${APT_CMD}" ]; then
  echo >&2 "Usage: $0 <apt_command>"
  exit 1
fi
if ! echo "${CONFIG_PREF}" | grep -Pq '^(new|old)$'; then
  echo >&2 "ERROR: Config. preference must be either 'new' or 'old'."
  exit 1
fi

hash apt-get 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }

# Ensure sudo privileges for the current user if not running as root.
if [[ $EUID -ne 0 ]]; then
  echo "NOTICE: Running as user $USER; sudo privileges required."
  if ! sudo echo "" > /dev/null 2>&1; then
    echo >&2 "ERROR: Must run with sudo privileges."
    exit 1
  fi
  PRE_CMD="sudo ${PRE_CMD}"
fi

if [ "${UPDATE}" == "1" ] || [ "${UPDATE}" == "true" ]; then
  UPDATE_CMD="${PRE_CMD} apt-get update"
  if ! ${UPDATE_CMD}; then
    echo >&2 "ERROR: Failed to update package cache."
    exit 1
  fi
fi

if [[ ${#DPKG_OPTS[@]} -ge 1 ]]; then
  for ((idx=0;idx<=$((${#DPKG_OPTS[@]}-1));idx++)); do
    dpkg_opt="${DPKG_OPTS[$idx]}"
    APT_ARGS="${APT_ARGS} -o Dpkg::Options::='${dpkg_opt}'"
  done
fi

# Combine complete command
BASH_CMD=$(echo "${PRE_CMD} ${BASH_ENV} bash -c \"apt-get ${APT_ARGS} ${APT_CMD}\"" | sed -e 's/^[ \t]*//')

echo "Running '${BASH_CMD}' ..."
BASH_CMD=$(echo "${PRE_CMD} ${BASH_ENV} bash" | sed -e 's/^[ \t]*//')
if ! ${BASH_CMD} -c "apt-get ${APT_ARGS} ${APT_CMD}"; then
  exit 1
fi

exit 0
