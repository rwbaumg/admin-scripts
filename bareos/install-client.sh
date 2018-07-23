#!/bin/bash
# Install Bareos FileDaemon on Ubuntu

UBUNTU_RELEASE=$(lsb_release -a 2>/dev/null | grep Release | awk '{print $2}')

echo "Installing Bareos FileDaemon for Ubuntu v${UBUNTU_VERSION} backup client..."

# add the package source
echo "deb http://download.bareos.org/bareos/release/latest/xUbuntu_${UBUNTU_RELEASE}/ ./" \
  | sudo tee -a /etc/apt/sources.list.d/bareos.list
if ! [ $? -eq 0 ]; then
  exit 1
fi

# add the release key
wget -qO - http://download.bareos.org/bareos/release/latest/xUbuntu_${UBUNTU_RELEASE}/Release.key \
  | sudo apt-key add -
if ! [ $? -eq 0 ]; then
  exit 1
fi

if [ -d /etc/.git  ]; then
  # commit /etc changes
  pushd /etc
  sudo git add --all /etc/apt
  sudo git commit -m "apt: add bareos package source"
  popd
fi

# update the package cache
sudo apt-get update
if ! [ $? -eq 0 ]; then
  exit 1
fi

# install the actual package
sudo apt-get install bareos-filedaemon
if ! [ $? -eq 0 ]; then
  exit 1
fi

if [ $? -eq 0 ]; then
  echo "Bareos FileDaemon installation successful."
fi

exit $?
