#!/bin/bash
# Output current WAN IP

ifconfig fwbr.wan| grep 'inet addr' | awk '{print $2}' | cut -f 2 -d ':'
