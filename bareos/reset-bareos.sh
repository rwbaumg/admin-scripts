#!/bin/bash
# 0x19e Networks
#
# Resets bareos storage and database
#
# Robert W. Baumgartner <rwb@0x19e.net>

# define the use to run database setup scripts as
SUDO_USER="postgres"

# stop all daemons
sudo service bareos-dir stop
sudo service bareos-fd stop
sudo service bareos-sd stop

# remove files
sudo rm -rf /var/lib/bareos/storage/*
sudo rm -rf /var/lib/bareos/bootstrap/*
sudo rm -rf /var/lib/bareos/spool/*
sudo rm /var/lib/bareos/*

# add postgres to bareos group
# this is required for setup scripts to read
# the bareos configuration files, but may not
# be good for production security.
sudo usermod -a -G bareos postgres

# drop databases
pushd /usr/lib/bareos/scripts
sudo -u $SUDO_USER ./drop_bareos_database

# (re-)create database
sudo -u $SUDO_USER ./create_bareos_database
sudo -u $SUDO_USER ./make_bareos_tables
sudo -u $SUDO_USER ./grant_bareos_privileges
popd

# remove postgres from the bareos group
# should not be required after setup is complete
sudo gpasswd -d postgres bareos

# restart daemons
sudo service bareos-dir start
sudo service bareos-fd start
sudo service bareos-sd start

exit 0
