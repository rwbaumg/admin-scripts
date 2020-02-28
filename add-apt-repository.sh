#!/bin/bash
# Alternative script to handle adding PPA sources for APT
# TODO: Backup apt/trusted.gpg and restore on rollback

#UBUNTU_VERSION="focal"
#UBUNTU_VERSION="devel"
UBUNTU_VERSION="bionic"

PPA_BASE_URL="http://ppa.launchpad.net"

if [ $# -ne 1 ]; then
	echo "Utility to add PPA repositories in your debian machine"
	echo "Usage: $0 ppa:user/ppa-name"
fi

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo >&2 "This script must be run as root."
   exit 1
fi

if ! NAME=$( (uname -a && date) | md5sum | cut -f1 -d" "); then
	echo >&2 "ERROR: Failed to calculate package identifier."
	exit 1
fi

if ! echo "$1" | grep -E '^ppa\:'; then
        echo >&2 "ERROR: Invalid PPA identifier: '$1'."
        exit 1
fi

ppa_name=$(echo "$1" | cut -d":" -f2 -s)
if [ -z "$ppa_name" ]; then
	echo >&2 "ERROR: PPA name not found."

	echo "Utility to add PPA repositories in your debian machine"
	echo "Usage: $0 ppa:user/ppa-name"
        exit 1
fi

if [ ! -d "/etc/apt/sources.list.d" ]; then
        echo >&2 "ERROR: Package source directory is missing: /etc/apt/sources.list.d"
        exit 1
fi

ppa_filename=$(echo "${ppa_name}" | sed -e 's/\//_/g')
ppa_output="/etc/apt/sources.list.d/${ppa_filename}.list"
if [ -e "${ppa_output}" ]; then
        echo >&2 "ERROR: Package source '${ppa_output}' already exists."
        exit 1
fi
if ! temp_file=$(mktemp -t "${NAME}_apt_add_key.XXXXXXXX.txt"); then
	echo >&2 "ERROR: Failed to create temporary file."
	exit 1
fi

echo "Adding PPA package source: ${ppa_name} ..."
echo "deb ${PPA_BASE_URL}/${ppa_name}/ubuntu ${UBUNTU_VERSION} main" > "${ppa_output}"

function rollback_changes()
{
        if [ -e "${temp_file}" ]; then
                rm -rv "${temp_file}"
        fi
        if [ -e "${ppa_output}" ]; then
                rm -rv "${ppa_output}"
        fi
}

# update package repositories and log errors to temp. file
apt update > /dev/null 2> "${temp_file}"

# check for and install missing keys for package signing
key=$(grep "NO_PUBKEY" "${temp_file}" | cut -d":" -f6 | cut -d" " -f3)
if [ -z "${key}" ]; then
	echo >&2 "ERROR: Failed to find signing key for package source."
        rollback_changes
	exit 1
fi

echo "Downloading PPA key (key id: $key) ..."
if ! apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key"; then
	echo >&2 "ERROR: Failed to retrieve PPA signing key."
        rollback_changes
	exit 1
fi

echo "Updating package cache ..."
if ! apt update; then
	echo >&2 "ERROR: Failed to install PPA: ${ppa_name}"
        rollback_changes
	exit 1
fi

echo "Removing temporary files..."
rm -rfv "${temp_file}"

echo "Finished."
exit 0
