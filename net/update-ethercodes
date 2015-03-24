#!/bin/bash
# update-ethercodes.sh
# This script downloads the currect mac address data from the IEEE and parses it for nmap and arpwatch.
# nmap-mac-prefixes is for nmap.
# ethercodes.dat is arpwatch.

# Download the current data

wget http://standards.ieee.org/regauth/oui/oui.txt

# Divide the data into Manufacturer and Address files
cat oui.txt | grep '(base 16)' | cut -f3 > mac.manufacturer
cat oui.txt | grep '(base 16)' | cut -f1 -d' ' > mac.address

# Paste them back together for nmap data
#paste mac.address mac.manufacturer > nmap-mac-prefixes

# Parse the address data for arpwatch
cat mac.address | perl -pe 's/^(([^0].)|0(.))(([^0].)|0(.))(([^0].)|0(.))/\2\3:\5\6:\8\9/' > tmp.address
cat tmp.address | tr [A-Z] [a-z] > mac.address

# Paste the parsed data into the arpwatch file
paste mac.address mac.manufacturer > ethercodes.dat

# Clean up intermediary files
rm tmp.address
rm mac.address
rm mac.manufacturer
rm oui.txt
