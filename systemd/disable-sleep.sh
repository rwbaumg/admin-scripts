#!/bin/bash
# Disable sleep/suspend/hibernate

TARGETS="sleep.target suspend.target hibernate.target hybrid-sleep.target"

hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }

# Ensure sudo privileges for the current user if not running as root.
if [[ $EUID -ne 0 ]]; then
  echo "NOTICE: Running as user $USER; sudo privileges required."
  if ! sudo echo "" > /dev/null 2>&1; then
    echo >&2 "ERROR: Must have sudo privileges to modify configuration files."
    exit 1
  fi
fi

systemd_cmd="systemctl mask ${TARGETS}"

# shellcheck disable=2086
if ! sudo $systemd_cmd; then
  echo >&2 "ERROR: Failed to disable sleep/suspend/hibernate targets."
  exit 1
fi

echo "Disabled systemd sleep/suspend/hibernate targets."
exit 0
