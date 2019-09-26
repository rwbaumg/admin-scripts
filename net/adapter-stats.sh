#!/bin/bash

# irqbalance

# ethtool -S eth0
# check buffers usage: ethtool -g eth0
# check offloading: ethtool -k eth0
# ip link <mtu n>
# check flow control: ethtool -a eth0
# check interrupt coalescence: ethtool -c eth0
#    ethtool -C eth0 adaptive-rx off rx-usecs off rx-frames 0

# sudo apt-get install numad
# ethtool -S ens1

# /sys/module/intel_idle/parameters/max_cstate
# processor.max_cstate=1 (prevent C-state below C1)
# For Intel, sometimes need: intel_idle.max_cstate=0

# sudo apt-get install powertop

# sudo apt-get install tuned
# tuned-adm list
# tuned-adm profile network-throughput
# /usr/lib/tuned /etc/tuned

netstat -su

ss -nmp | grep tcp

# If 2nd column in /proc/net/softnet_stat is incremented over time, increase netdev_max_backlog

# net.core.netdev_budget (default: 300) can be doubled if the value in the 3rd column in /proc/net/softnet_stat os increasing:
#  sysctl -w net.core.netdev_budget=600

# Check how many connections are used by proc
# netstat -neopa | grep -E 'tcp|udp'

# /proc/interrupts
# /proc/net/softnet_stat

