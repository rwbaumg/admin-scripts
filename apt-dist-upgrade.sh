#!/bin/bash
# Runs apt-get dist-upgrade so you don't develop carpel-tunnel
# from upgrading your system all the time like you should.

# Note: All arguments are passed to apt-get

sudo apt-get $@ update && \
sudo apt-get $@ dist-upgrade && \
sudo apt-get $@ autoremove
