#!/bin/bash
# updates the PCI ID database

DOWNLOAD_URL="https://github.com/pciutils/pciids/raw/master/pci.ids"
# DOWNLOAD_URL="http://pci-ids.ucw.cz/v2.2/pci.ids"

hash wget 2>/dev/null || { echo >&2 "You need to install wget. Aborting."; exit 1; }

# download the database
wget -N $DOWNLOAD_URL
