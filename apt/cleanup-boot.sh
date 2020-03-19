#!/bin/bash
# Clean up the /boot partition
# DANGER: This script is dangerous!
# Only run it if you know what you
# are doing.

hash dpkg 2>/dev/null || { echo >&2 "You need to install dpkg. Aborting."; exit 1; }
hash apt-get 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }
hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }

# Ensure sudo privileges for the current user if not running as root.
if [[ $EUID -ne 0 ]]; then
  echo "NOTICE: Running as user $USER; sudo privileges required."
  if ! sudo echo "" > /dev/null 2>&1; then
    echo >&2 "ERROR: Must have sudo privileges to modify configuration files."
    exit 1
  fi
fi

dpkg -l 'linux-*' \
| sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' \
| xargs sudo apt-get -y purge
