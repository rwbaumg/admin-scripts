#!/bin/bash
# 0x19e Networks
#
# Clears the cache and restarts the Bareos director
#
# Robert W. Baumgartner <rwb@0x19e.net>

echo ".bvfs_clear_cache yes" | sudo bconsole
sudo service bareos-dir restart
echo ".bvfs_update" | sudo bconsole
