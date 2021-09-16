#!/bin/bash
# Allow colord for all users
# Fixes issues associated with xRDP permissions

BASE_PATH=$(dirname "$0")

CONFIG_DIR="/etc/polkit-1/localauthority/50-local.d"
NEW_CONFIG="45-allow-colord.pkla"

hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }

if [ ! -d "${CONFIG_DIR}" ]; then
  echo >&2 "ERROR: Configuration directory '${CONFIG_DIR}' does not exist. Aborting."
  exit 1
fi

if [ -e "${CONFIG_DIR}/${NEW_CONFIG}" ]; then
  echo "Configuration file '${NEW_CONFIG}' is already installed."
  exit 0
fi

echo "Installing configuration file..."
if ! cp -v "${BASE_PATH}/configs/xrdp/${NEW_CONFIG}" "${CONFIG_DIR}"/; then
  echo >&2 "ERROR: Failed to install configuration file."
  exit 1
fi

echo "Done."
exit 0
