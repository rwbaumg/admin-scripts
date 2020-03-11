#!/bin/bash
# backup apt packages
# To restore:
#  - 'dpkg --set-selections < selections.txt && apt-get dselect-upgrade'

hash dpkg 2>/dev/null || { echo >&2 "You need to install dpkg. Aborting."; exit 1; }
hash apt-key 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }

if ! dpkg --get-selections > installed_packages.log; then
  echo >&2 "ERROR: Failed to export package selections."
  exit 1
fi

if ! apt-key exportall > repositories.keys 2>/dev/null; then
  echo >&2 "ERROR: Failed to export package repositories."
  exit 1
fi

exit 0
