#!/bin/sh
# Upgrade all packages

hash opkg 2>/dev/null || { echo >&2 "Could not find opkg command in PATH. Aborting."; exit 1; }

if ! PKG_LIST=$(opkg list-upgradable | cut -f 1 -d ' '); then
  echo >&2 "The list-upgradable command returned a non-zero exit code. Aborting..."
  exit 1
fi

if [ -z "${PKG_LIST}" ]; then
  echo "No packages to upgrade."
  exit 0
fi

if ! echo "${PKG_LIST}" | xargs opkg upgrade; then
  exit 1
fi

exit 0
