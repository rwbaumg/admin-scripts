#!/bin/bash
#
# [0x19e Nentworks]
# Robert W. Baumgartner <rwb@0x19e.net>
#
# Bareos LTO Hardware Encryption Backup Script
#
# Creates a backup file for harware-encrypted LTO tape storage
# This can be used as part of a post-script to ensure keys are
# backed up to a safe location for disaster recovery.

# Settings
DIR_CONFIG_NAME="bareos-dir"
DIR_CONFIG_PATH="/etc/bareos/bareos-sd.d/director"

# Configure database columns to include in direct PSQL dumps.
# Available columns: mediaid, volumename, slot, poolid, mediatype, mediatypeid, labeltype, firstwritten, lastwritten,
#                    labeldate, voljobs, volfiles, volblocks, volmounts, volbytes, volerrors, volwrites, volcapacitybytes,
#                    volstatus, enabled, recycle, actiononpurge, volretention, voluseduration, maxvoljobs, maxvolfiles,
#                    maxvolbytes, inchanger, storageid, deviceid, mediaaddressing, volreadtime, volwritetime, endfile,
#                    endblock, locationid, recyclecount, minblocksize, maxblocksize, initialwrite, scratchpoolid,
#                    recyclepoolid, encryptionkey, comment
PSQL_SELECT_COLUMNS="volumename,volstatus,firstwritten,lastwritten,encryptionkey"

# Generate a timestamp to include in output
TIMESTAMP=$(date '+%Y-%m-%d %r')

# Make sure 'bareos-sd' and 'bscrypto' are installed
hash bareos-sd 2>/dev/null || { echo >&2 "You need to install bareos-storage. Aborting."; exit 1; }
hash bscrypto 2>/dev/null || { echo >&2 "You need to install bareos-storage-tape. Aborting."; exit 1; }
hash psql 2>/dev/null || { echo >&2 "You need to install postgresql-client-common. Aborting."; exit 1; }
hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }

# Enable overriding director name
if [ -n "$1" ]; then
  DIR_CONFIG_NAME="$1"
fi

CONFIG_PATH="${DIR_CONFIG_PATH}/${DIR_CONFIG_NAME}.conf"
if [ ! -e "${CONFIG_PATH}" ]; then
  echo >&2 "ERROR: Configuration file '${CONFIG_PATH}' could not be found."
  echo >&2 "Try specifying the director name with '$0 <dir-name>'"
  exit 1
fi

# Determine the configured port for the Storage Daemon
SD_PORT=9103
CFG_PORT=$(grep -Po "[Ss][Dd](?:\\s?)[Pp][Oo][Rr][Tt](?:\\s?)=(?:\\s?)\\d+" "${CONFIG_PATH}" | awk -F= '{ print $2 }' | awk '{$1=$1};1')
if [ -n "${CFG_PORT}" ]; then
  SD_PORT=${CFG_PORT}
fi

if [[ "$USER" == "bareos" ]] || [[ $EUID -eq 0 ]]; then
  PSQL_CMD="psql -d bareos -w"
  if [[ $EUID -eq 0 ]]; then
    PSQL_CMD="sudo -u bareos ${PSQL_CMD}"
  fi
  # Dump directly from the database
  PSQL_QUERY="SELECT ${PSQL_SELECT_COLUMNS} FROM media WHERE encryptionkey IS NOT NULL AND encryptionkey != '' ORDER BY lastwritten DESC;"
  if ! CRYPTOC_DUMP=$(echo "${PSQL_QUERY}" | ${PSQL_CMD} | grep -v "rows)"); then
    echo >&2 "WARNING: Failed to dump keys from database."
    CRYPTOC_DUMP=""
  fi
fi

if [ -z "${CRYPTOC_DUMP}" ]; then
  # Dump the crypto cache
  CRYPTCACHE_PATH="/var/lib/bareos/bareos-sd.${SD_PORT}.cryptoc"
  if [ ! -e "${CRYPTCACHE_PATH}" ]; then
    echo >&2 "ERROR: Crypto cache file '${CRYPTCACHE_PATH}' does not exist."
    exit 1
  fi
  CRYPTOC_DUMP=$(bscrypto -D "${CRYPTCACHE_PATH}")
fi

# Get the Key Encryption Key
KEK=$(grep "Key Encryption Key" "${CONFIG_PATH}" | awk -F" = " '{ print $2 }' | sed -e 's/^"//' -e 's/"$//')

# Print results to stdout
echo "${TIMESTAMP} : Bareos LTO Encryption Backup"
echo
echo "Bareos Director Name   : ${DIR_CONFIG_NAME}"
echo "Key Encryption Key     : ${KEK}"
echo
echo "${CRYPTOC_DUMP}"

exit 0
