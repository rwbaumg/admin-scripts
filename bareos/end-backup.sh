#!/bin/bash
# releases the tape after nightly catalog backups

if [ ! -e "/usr/lib/bareos/scripts/delete_catalog_backup" ]; then
  echo >&2 "ERROR: Missing Bareos script: /usr/lib/bareos/scripts/delete_catalog_backup"
  exit 1
fi

# delete the catalog backup
/usr/lib/bareos/scripts/delete_catalog_backup

# rewind and eject the current tape
hash mt 2>/dev/null || { echo >&2 "You need to install mt-st; cannot eject tape."; exit 1; }
mt rewind
mt eject

exit 0
