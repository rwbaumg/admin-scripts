#!/bin/bash
# perform post-backup catalog maintenence

CATALOG="BareosCatalog"
STATS_DAYS=14

hash bconsole 2>/dev/null || { echo >&2 "You need to install bareos-bconsole. Aborting."; exit 1; }

if ! OUTPUT=$(bconsole << END_OF_DATA
@output /dev/null
@output
use catalog=${CATALOG}
update stats days=${STATS_DAYS}
prune stats yes
.bvfs_update
quit
END_OF_DATA
); then
  echo >&2 "ERROR: Failed running post-backup maintenence for catalog ${CATALOG}."
  if [ -n "${OUTPUT}" ]; then
    echo >&2 "ERROR: Command output: ${OUTPUT}"
  fi
  exit 1
fi

exit 0
