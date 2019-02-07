#!/bin/bash
# Install Bareos FileDaemon on Ubuntu

hash wget 2>/dev/null || { echo >&2 "You need to install wget. Aborting."; exit 1; }
hash apt-get 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }

UBUNTU_RELEASE=$(lsb_release -a 2>/dev/null | grep Release | awk '{print $2}')

echo "Installing Bareos FileDaemon for Ubuntu v${UBUNTU_RELEASE} backup client..."

PKG_LST="/etc/apt/sources.list.d/bareos.list"
PKG_SRC="deb http://download.bareos.org/bareos/release/latest/xUbuntu_${UBUNTU_RELEASE}/ ./"
PKG_KEY="http://download.bareos.org/bareos/release/latest/xUbuntu_${UBUNTU_RELEASE}/Release.key"

# add the package source
echo "Configuring package source in list file ${PKG_LIST} ..."
grep -qF "${PKG_SRC}" "${PKG_LST}"  || echo "${PKG_SRC}" | sudo tee -a "${PKG_LST}"
if ! [ $? -eq 0 ]; then
  exit 1
fi

# add the release key
echo "Retrieve release signing key ..."
wget -qO - "${PKG_KEY}"  | sudo apt-key add -
if ! [ $? -eq 0 ]; then
  exit 1
fi

if [ -d /etc/.git  ] && hash git 2>/dev/null; then
  # commit /etc changes
  echo "Auto-commit changes to /etc (directory under version control) ..."
  pushd /etc
  sudo git add --all /etc/apt
  sudo git commit -v -m "apt: add bareos package source"
  popd
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
  exit 1
fi

if [ $? -eq 0 ]; then
  echo "Bareos FileDaemon installation successful."
fi

exit $?
