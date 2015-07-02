#!/bin/bash
# backup apt packages

dpkg --get-selections > installed_packages.log
apt-key exportall > repositories.keys
