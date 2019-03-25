#!/bin/bash
# Install Bareos FileDaemon on Ubuntu

hash wget 2>/dev/null || { echo >&2 "You need to install wget. Aborting."; exit 1; }
hash apt-get 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }

UBUNTU_RELEASE=$(lsb_release -a 2>/dev/null | grep Release | awk '{print $2}')
if [ -z "${UBUNTU_RELEASE}" ]; then
  echo >&2 "ERROR: Unable to determine Ubuntu release."
  exit 1
fi

echo "Installing Bareos FileDaemon for Ubuntu v${UBUNTU_RELEASE} backup client..."

HTPROTO="http"

PKG_LST="/etc/apt/sources.list.d/bareos.list"
PKG_SRC="download.bareos.org/bareos/release/latest/xUbuntu_${UBUNTU_RELEASE}/ ./"
PKG_KEY="download.bareos.org/bareos/release/latest/xUbuntu_${UBUNTU_RELEASE}/Release.key"

DEB_TXT="deb ${HTPROTO}://${PKG_SRC}"
KEY_URL="${HTPROTO}://${PKG_KEY}"

# add the package source
echo "Configuring package source in list file ${PKG_LIST} ..."
if [ ! -e "${PKG_LST}" ] || ! grep -qF "${PKG_SRC}" "${PKG_LST}"; then
  echo "${DEB_TXT}" | sudo tee -a "${PKG_LST}"
  if ! [ $? -eq 0 ]; then
    exit 1
  fi
fi

# add the release key
echo "Retrieve release signing key ..."
wget -qO - "${KEY_URL}"  | sudo apt-key add -
if ! [ $? -eq 0 ]; then
  exit 1
fi

# git handling for etckeeper (check if /etc/.git exists)
if [ -d /etc/.git  ] && hash git 2>/dev/null; then
  if `git -C "/etc" rev-parse > /dev/null 2>&1`; then
    # check /etc/apt for modifications
    # if there are changes, commit them
    if [[ "$(git --git-dir=/etc/.git --work-tree=/etc status --porcelain -- /etc/apt|egrep '^(M| M)')" != "" ]]; then
      echo "Auto-commit changes to /etc/apt (directory under version control) ..."
      pushd /etc > /dev/null 2>&1
      sudo git add --all /etc/apt
      sudo git commit -v -m "apt: add bareos package source"
      popd > /dev/null 2>&1
    fi
  fi
fi

# update the package cache
echo "Updating package list ..."
sudo apt-get update
if ! [ $? -eq 0 ]; then
  exit 1
fi

# install the actual package
echo "Running installation ..."
sudo apt-get install bareos-filedaemon -y
if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed to install Bareos client."
  exit 1
fi

if [ $? -eq 0 ]; then
  echo "Bareos FileDaemon installation successful."
fi

exit $?
