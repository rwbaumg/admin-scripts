#!/bin/bash
# 0x19e Networks
#
# Resets a client's Bareos File Daemon
#
# Robert W. Baumgartner <rwb@0x19e.net>

sudo service bareos-fd stop
sudo rm /var/lib/bareos/*
sudo service bareos-fd start
