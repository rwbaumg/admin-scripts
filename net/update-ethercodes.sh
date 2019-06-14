#!/bin/bash
# update-ethercodes.sh
# This script downloads the currect mac address data from the IEEE and parses it for nmap and arpwatch.
# nmap-mac-prefixes is for nmap.
# ethercodes.dat is arpwatch.

# Download the current data

wget -N http://standards.ieee.org/regauth/oui/oui.txt

# Divide the data into Manufacturer and Address files
grep '(base 16)' oui.txt | cut -f3 > mac.manufacturer
grep '(base 16)' oui.txt | cut -f1 -d' ' > mac.address

# Paste them back together for nmap data
#paste mac.address mac.manufacturer > nmap-mac-prefixes

# Parse the address data for arpwatch
perl -pe 's/^(([^0].)|0(.))(([^0].)|0(.))(([^0].)|0(.))/\2\3:\5\6:\8\9/' mac.address > tmp.address
tr '[:upper:]' '[:lower:]' < tmp.address > mac.address

# Paste the parsed data into the arpwatch file
paste mac.address mac.manufacturer > ethercodes.dat

# Clean up intermediary files
rm tmp.address
rm mac.address
rm mac.manufacturer

# rm oui.txt
