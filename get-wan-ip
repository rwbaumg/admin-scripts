#!/bin/bash
# Output current WAN IP

# IGNORE_ADDRS=("127.0.0.1" "10.6.6")

ifconfig | grep 'inet addr:' \
         | grep -v '127.0.0.1' \
         | cut -d: -f2 \
         | awk '{ print $1}'

#ifconfig | grep 'inet addr:'| grep -v '127.0.0.1' | grep -v '10.6.6' | cut -d: -f2 | awk '{ print $1}'

# ifconfig fwbr.wan| grep 'inet addr' | awk '{print $2}' | cut -f 2 -d ':'
