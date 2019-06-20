#!/bin/bash
# List PCI devices

# list pci id, class, vendor and device ids
# for device in /sys/bus/pci/devices/*; do echo "$(basename ${device} | cut -c '6-') $(cut -c '3-6' ${device}/class): $(cut -c '3-' ${device}/vendor):$(cut -c '3-' ${device}/device)"; done

# list vga devices
for I in $(lspci |awk '/VGA/{print $1}');do lspci -v -s "$I"; done
# lspci -v | perl -ne '/VGA/../^$/ and /VGA|Kern/ and print'
