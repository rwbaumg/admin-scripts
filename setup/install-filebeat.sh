#!/bin/bash
# Install Elastic Filebeat
# See https://www.elastic.co/guide/en/elasticsearch/reference/current/deb.html
# Repo. URL: https://artifacts.elastic.co/packages

hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }
hash apt-key 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }
hash wget 2>/dev/null || { echo >&2 "You need to install wget. Aborting."; exit 1; }

PKG_NAME="filebeat"
PKG_VERSION="7.x"
PKG_SRC_URL="https://artifacts.elastic.co/packages"
GPG_KEY_URL="https://artifacts.elastic.co/GPG-KEY-elasticsearch"

function check_installed() {
  pkg_name="$1"
  if [ -z "${pkg_name}" ]; then
    echo >&2 "ERROR: Package name not provided to check script."
    exit 1
  fi

  if hash apt-cache 2>/dev/null; then
    if apt-cache policy "${pkg_name}" | grep -v '(none)' | grep -q Installed; then
      return 0
    fi
  fi

  return 1
}

# Attempt to install a package
function install_pkg() {
  pkg_name="$1"
  if [ -z "${pkg_name}" ]; then
    echo >&2 "ERROR: Package name not provided to check script."
    return 1
  fi

  if check_installed "${pkg_name}"; then
    # package is already installed
    return 0
  fi

  if hash apt 2>/dev/null; then
    echo "Updating package cache..."
    if ! sudo apt update; then
      echo >&2 "ERROR: Failed to update package cache."
      return 1
    fi
  fi

  echo "Installing package '${pkg_name}' via apt ..."
  if ! sudo apt install -V -y "${pkg_name}"; then
    echo >&2 "ERROR: Failed to install package '${pkg_name}'."
    return 1
  fi

  return 0
}

if check_installed "${PKG_NAME}"; then
  echo "Package '${PKG_NAME}' is already installed."
  exit 0
fi

if ! install_pkg "apt-transport-https"; then
  exit 1
fi

echo "Installing Elastic GPG signing key ..."
if ! wget -qO - "${GPG_KEY_URL}" | sudo apt-key add -; then
  echo "ERROR: Failed to install signing key." >&2
  exit 1
fi

if [ ! -e "/etc/apt/sources.list.d/elastic-${PKG_VERSION}.list" ]; then
  echo "Installing APT package source ..."
  if ! echo "deb ${PKG_SRC_URL}/${PKG_VERSION}/apt stable main" \
           | sudo tee -a "/etc/apt/sources.list.d/elastic-${PKG_VERSION}.list"; then
    echo "ERROR: Failed to install APT package source."
    exit 1
  fi
fi

if ! install_pkg "${PKG_NAME}"; then
  exit 1
fi

exit 0
