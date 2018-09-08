#!/bin/bash
# backup apt packages

hash dpkg 2>/dev/null || { echo >&2 "You need to install dpkg. Aborting."; exit 1; }
hash apt-get 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }

dpkg --get-selections > installed_packages.log
apt-key exportall > repositories.keys
