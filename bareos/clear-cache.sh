#!/bin/bash
# 0x19e Networks
#
# Clears the cache and restarts the Bareos director
#
# Robert W. Baumgartner <rwb@0x19e.net>

hash bconsole 2>/dev/null || { echo >&2 "You need to install bareos-bconsole. Aborting."; exit 1; }

echo ".bvfs_clear_cache yes" | sudo bconsole
sudo service bareos-dir restart
echo ".bvfs_update" | sudo bconsole
