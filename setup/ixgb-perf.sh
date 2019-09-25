#!/bin/bash
# Configure performance settings for 10GbE networking (ixgbe)
# To view link messages, set dmesg to 8; run: 'dmesg -n 8' (note: this setting is not saved across reboots)

# Step 1: Use 'ip link' to modify the mtu (maximum transmission unit) and the txqueuelen parameter.
# Step 2: Use 'sysctl' to modify /proc parameters (essentially kernel tuning)
# Step 3: Use 'setpci' to modify the MMRBC field in PCI-X configuration space to increase transmit burst lengths on the bus.

# NOTE: setpci modifies the adapter's configuration registers to allow it to read up to 4k bytes
# at a time (for transmits). However, for some systems the behavior after modifying this register
# may be undefined (possibly errors of some kind). A power-cycle, hard reset or explicitly setting
# the e6 register back to 22 (setpci -d 8086:1a48 e6.b=22) may be required to get back to a stable
# configuration.

# Under stress conditions, if TX hangs occur, turning off TSO "ethtool -K eth0 tso off" may resolve the problem.

# Due to the default ARP behavior on Linux, it is not possible to have one system on two IP networks in the same Ethernet broadcast domain (non-partitioned switch) behave as expected. All Ethernet interfaces will respond to IP traffic for any IP address assigned to the system. This results in unbalanced receive traffic.
#   If you have multiple interfaces in a server, do either of the following:
#   -  Turn on ARP filtering by entering:
#        echo 1 > /proc/sys/net/ipv4/conf/all/arp_filter
# Install the interfaces in separate broadcast domains - either in different switches or in a switch partitioned to VLANs.

# For Linux driver information: https://www.kernel.org/doc/html/latest/networking/device_drivers/intel/ixgb.html
# For a list of sysctl parameters: https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt
# For NAPI information: https://wiki.linuxfoundation.org/networking/napi
# Kernel TLS offloading: https://www.kernel.org/doc/html/latest/networking/tls-offload.html

DEVICE="eth0"
BASE_PATH=$(dirname "$0")

echo "configuring network performance for $DEVICE , edit this file to change the interface or device ID of 10GbE card"

# set mmrbc to 4k reads, modify only Intel 10GbE device IDs
# replace 1a48 with appropriate 10GbE device's ID installed on the system,
# if needed.
# setpci -v -d 8086:1a48 e6.b=2e
# setpci -v -d 8086:1528 e6.b=2e

# fix slow udp traffic
sysctl -w net.core.rmem_max=262143
sysctl -w net.core.rmem_default=262143

# set the MTU (max transmission unit) - it requires your switch and clients to change as well.
# set the txqueuelen
# your ixgb adapter should be loaded for this to work, change if needed
# ip li set dev "$DEVICE" mtu 9000 txqueuelen 1000 up

# Enable Jumbo Frames
ip li set dev "$DEVICE" mtu 9000
# Set Max. Queue Length
ip li set dev "$DEVICE" txqueuelen 1000

# call the sysctl utility to modify /proc/sys entries
sysctl -p "${BASE_PATH}/configs/sysctl_ixgb.conf"
