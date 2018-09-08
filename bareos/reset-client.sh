#!/bin/bash
# 0x19e Networks
#
# Resets a client's Bareos File Daemon
#
# Robert W. Baumgartner <rwb@0x19e.net>

hash bareos-fd 2>/dev/null || { echo >&2 "You need to install bareos-filedaemon. Aborting."; exit 1; }

sudo service bareos-fd stop
sudo rm /var/lib/bareos/*
sudo service bareos-fd start
