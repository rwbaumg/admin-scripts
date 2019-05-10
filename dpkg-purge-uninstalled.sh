#!/bin/bash
# Purges configurations for uninstalled packages
# WARNING: This script deletes data! Make sure you have backups.

sudo dpkg --purge $(COLUMNS=300 dpkg -l "*" | grep "^rc" | cut -d\  -f3)

exit 0
