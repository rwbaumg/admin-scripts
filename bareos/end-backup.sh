#!/bin/bash
# releases the tape after nightly catalog backups
/usr/lib/bareos/scripts/delete_catalog_backup
mt rewind
mt eject
exit 0
