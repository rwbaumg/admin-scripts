#!/bin/bash
# Alternative script to handle adding PPA sources for APT

#UBUNTU_VERSION="focal"
#UBUNTU_VERSION="devel"
UBUNTU_VERSION="bionic"

PPA_BASE_URL="http://ppa.launchpad.net"

if [ $# -ne 1 ]; then
	echo "Utility to add PPA repositories to your Debian-based system."
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
	if [ ! -z "${apt_trusted_backup}" ]; then
		if [ -e "${apt_trusted_backup}" ]; then
			echo >&2 "Restoring /etc/apt/trusted.gpg from backup ..."
			if ! cp -v "${apt_trusted_backup}" "/etc/apt/trusted.gpg"; then
				echo >&2 "WARNING: Failed to restore /etc/apt/trusted.gpg"
			fi
			echo >&2 "Removing backup file ..."
			if ! rm -v "${apt_trusted_backup}"; then
				echo >&2 "WARNING: Failed to delete backup file '${apt_trusted_backup}'."
			fi
		else
			echo >&2 "WARNING: Keys backup '${apt_trusted_backup}' does not exist."
		fi
	fi
        if [ -e "${temp_file}" ]; then
		echo >&2 "Removing temporary file ..."
                rm -rv "${temp_file}"
        fi
        if [ -e "${ppa_output}" ]; then
                rm -rv "${ppa_output}"
        fi
}

# update package repositories and log errors to temp. file
echo "Performing online check for missing package key (this might take a minute) ..."
apt update > /dev/null 2> "${temp_file}"

# check for and install missing keys for package signing
key=$(grep "NO_PUBKEY" "${temp_file}" | cut -d":" -f6 | cut -d" " -f3)
if grep "NO_PUBKEY" "${temp_file}" && [ -z "${key}" ]; then
	echo >&2 "ERROR: Failed to find signing key for package source."
        rollback_changes
	exit 1
fi

echo "Creating backup of /etc/apt/trusted.gpg ..."
if ! apt_trusted_backup=$(mktemp -t "apt_trusted.XXXXXXXX.bak"); then
	echo >&2 "ERROR: Failed to create temporary file."
	apt_trusted_backup=""
        rollback_changes
	exit 1
fi
if ! cp -v "/etc/apt/trusted.gpg" "${apt_trusted_backup}"; then
	echo >&2 "ERROR: Failed to create backup of /etc/apt/trusted.gpg."
	apt_trusted_backup=""
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
rm -rfv "${apt_trusted_backup}"

echo "Finished."
exit 0
