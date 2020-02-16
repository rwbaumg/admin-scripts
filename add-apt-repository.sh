#!/bin/bash
# Alternative script to handle adding PPA sources for APT

#UBUNTU_VERSION="focal"
#UBUNTU_VERSION="devel"
UBUNTU_VERSION="bionic"

if [ $# -ne 1 ]; then
	echo "Utility to add PPA repositories in your debian machine"
	echo "$0 ppa:user/ppa-name"
fi

if ! NAME=$(echo "$(uname -a && date)" | md5sum | cut -f1 -d" "); then
	echo >&2 "ERROR: Failed to calculate package identifier."
	exit 1
fi

ppa_name=$(echo "$1" | cut -d":" -f2 -s)
if [ -z "$ppa_name" ]; then
	echo "PPA name not found"
	echo "Utility to add PPA repositories in your debian machine"
	echo "$0 ppa:user/ppa-name"
else
	echo "Adding PPA package source: $ppa_name ..."
	echo "deb http://ppa.launchpad.net/$ppa_name/ubuntu ${UBUNTU_VERSION} main" >> /etc/apt/sources.list
	if ! apt update >> /dev/null 2> "/tmp/${NAME}_apt_add_key.txt"; then
		echo >&2 "WARNING: Failed to update package cache."
		#exit 1
	fi
	# TODO: Broken; multiple lines returned as written
	key=$(cat "/tmp/${NAME}_apt_add_key.txt" | cut -d":" -f6 | cut -d" " -f3)
	if [ -z "${key}" ]; then
		echo >&2 "ERROR: Failed to find signing key for package source."
		exit 1
	fi
	echo "Downloading PPA key (key id: $key) ..."
	if ! apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key"; then
		echo >&2 "ERROR: Failed to retrieve PPA signing key."
		exit 1
	fi
	echo "Removing temporary files..."
	rm -rfv "/tmp/${NAME}_apt_add_key.txt"
fi

echo "Finished."
exit 0
