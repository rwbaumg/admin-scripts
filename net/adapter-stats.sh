#!/bin/bash

# iperf3
# netperf

# iperf3 -s -p 8000 -d -V
# iperf3 -c client1.example.com -p 8000 -t 10 -i 1 -w 17520

# # allow incoming netperf connections
# sudo iptables -I INPUT -p tcp -m tcp --dport 12865 -j ACCEPT \
#   && sudo iptables -I INPUT -p udp -m udp --dport 12865 -j ACCEPT

# sudo service netperf start
# netperf -H nemesis -p 12865 -t TCP_STREAM -P 0 -c -l 10 -- -m 32K -M 32K -s 256K -S 256K
# netperf -H nemesis -p 12865 -t TCP_RR -c -l 10

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

