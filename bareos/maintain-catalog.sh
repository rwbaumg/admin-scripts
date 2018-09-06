#!/bin/bash
# perform post-backup catalog maintenence

CATALOG="BareosCatalog"
STATS_DAYS=14

bconsole <<END_OF_DATA 2>&1 >/dev/null
@output /dev/null
@output
use catalog=${CATALOG}
update stats days=${STATS_DAYS}
prune stats yes
.bvfs_update
quit
END_OF_DATA

if ! [ $? -eq 0 ]; then
  echo >&2 "ERROR: Failed running post-backup maintenence for catalog ${CATALOG}."
  exit 1
fi

exit 0
