#!/bin/bash
# Create a new source list of pkg-src entries derived from primary sources.
# Reads /etc/apt/sources.list and creates /etc/apt/sources.list.d/deb-src.list

hash apt-get 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }

# Ensure sudo privileges for the current user if not running as root.
if [[ $EUID -ne 0 ]]; then
  echo "NOTICE: Running as user $USER; sudo privileges required."
  if ! sudo echo "" > /dev/null 2>&1; then
    echo >&2 "ERROR: Must have sudo privileges to modify configuration files."
    exit 1
  fi
fi

if [ ! -e "/etc/apt/sources.list" ]; then
  echo >&2 "ERROR: Missing /etc/apt/sources.list"
  exit 1
fi

if ! grep '^deb ' /etc/apt/sources.list | \
       sed 's/^deb /deb-src /g' | \
      sudo tee /etc/apt/sources.list.d/deb-src.list; then
  echo >&2 "ERROR: Failed to create new source file."
  exit 1
fi

if ! sudo apt-get update -y; then
  echo >&2 "ERROR: Failed to update package cache; rolling back changes ..."
  sudo rm -vi "/etc/apt/sources.list.d/deb-src.list"
  exit 1
fi

exit 0
