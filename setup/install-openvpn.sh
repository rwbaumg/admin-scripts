#!/bin/bash
# Install OpenVPN client on Debian-based system
# Package list is defined after include_packages() function.

DRY_RUN=0

function check_installed() {
  pkg_name="$1"
  if [ -z "${pkg_name}" ]; then
    echo >&2 "ERROR: Package name not provided to check script."
    exit 1
  fi

  if hash apt-cache 2>/dev/null; then
    if apt-cache policy "${pkg_name}" | grep -v '(none)' | grep -q "Installed"; then
      return 0
    fi
  fi

  return 1
}

declare -a missing=();
function include_package()
{
  if [ -z "$1" ]; then
    echo >&2 "ERROR: Package name cannot be null."
    exit 1
  fi
  package_name="$1"
  missing=("${missing[@]}" "${package_name}")
}

echo "Preparing to install OpenVPN ..."

#########################################################################

## Add list of packages to be installed.
# Base packages
include_package "openvpn"
include_package "easy-rsa"
include_package "anytun"

# Name resolution
include_package "resolvconf"

## Only install if systemd is installed
if check_installed "systemd"; then
  echo "Detected systemd; marking openvpn-systemd-resolved package for installation..."
  include_package "openvpn-systemd-resolved"
fi

## Only install if network-manager is present
if check_installed "network-manager"; then
  echo "Found network-manager package; marking network-manager-openvpn package for installation..."
  include_package "network-manager-openvpn"

  ## Only install if GNOME is present
  if check_installed "gnome-shell"; then
    echo "GNOME detected; marking network-manager-openvpn-gnome package for installation..."
    include_package "network-manager-openvpn-gnome"
  fi
fi

# (Optional) Authentication modules
#include_package "openvpn-auth-ldap"
#include_package "openvpn-auth-radius"

#########################################################################

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

# Attempt to install packages
function install_packages() {
  pkg_names="$1"
  if [ -z "${pkg_names}" ]; then
    echo >&2 "ERROR: Package names not provided to check script."
    return 1
  fi

  if hash apt-get 2>/dev/null; then
    echo "Updating APT cache..."
    if ! do_with_root "apt-get update"; then
      echo >&2 "ERROR: Failed to update APT cache."
      return 1
    fi
  fi

  echo "Installing missing packages via apt-get ..."
  cmd_extra=""
  if [ "${DRY_RUN}" == "1" ]; then
    cmd_extra="--dry-run"
    echo >&2 "WARNING: DRY RUN"
  fi
  apt_cmd="apt-get install ${cmd_extra} -V -y ${pkg_names}"
  if ! do_with_root "${apt_cmd}"; then
    echo >&2 "ERROR: Failed to install '${pkg_names}'."
    return 1
  fi

  return 0
}

err=0
pkg_string=""
for ((idx=0;idx<=$((${#missing[@]}-1));idx++)); do
  pkg="${missing[$idx]}"

  if check_installed "${pkg}"; then
    # package is already installed
    echo "Package '${pkg}' is already installed."
  else
    echo "Found package to install: ${pkg}"
    if [ $idx -eq 0 ]; then
      pkg_string="${pkg}"
    else
      pkg_string="${pkg_string} ${pkg}"
    fi
  fi
done

if [ -z "${pkg_string}" ]; then
  echo >&2 "ERROR: No packages to install."
  exit 1
fi

if ! install_packages "${pkg_string}"; then
  err=1
fi

exit "$err"
