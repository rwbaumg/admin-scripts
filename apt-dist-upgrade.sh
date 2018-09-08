#!/bin/bash
# Runs apt-get dist-upgrade so you don't develop carpel-tunnel
# from upgrading your system all the time like you should.

# Note: All arguments are passed to apt-get

hash apt-get 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }

sudo apt-get $@ update && \
sudo apt-get $@ dist-upgrade && \
sudo apt-get $@ autoremove
