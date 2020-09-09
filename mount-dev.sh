#!/bin/bash
#
# -=[ 0x19e Networks ]=-
#
# Mounts all partitiions detected in the specified device.
# Uses kpartx to manage block device mappings
#
# Author: Robert W. Baumgartner <rwb@0x19e.net>
#
DEFAULT_MOUNTPOINT="/media/lvm"
DEFAULT_MOUNT_OPTS="rw"

hash lvs 2>/dev/null || { echo >&2 "You need to install lvm2. Aborting."; exit 1; }
hash kpartx 2>/dev/null || { echo >&2 "You need to install kpartx. Aborting."; exit 1; }
hash blkid 2>/dev/null || { echo >&2 "You need to install util-linux. Aborting."; exit 1; }
hash awk 2>/dev/null || { echo >&2 "You need to install awk. Aborting."; exit 1; }


exit_script()
{
  # Default exit code is 1
  local exit_code=1
  local re

  re='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'
  if echo "$1" | grep -qE "$re"; then
    exit_code=$1
    shift
  fi

  re='[[:alnum:]]'
  if echo "$@" | grep -iqE "$re"; then
    if [ "$exit_code" -eq 0 ]; then
      echo "INFO: $*"
    else
      echo "ERROR: $*" 1>&2
    fi
  fi

  # Print 'aborting' string if exit code is not 0
  [ "$exit_code" -ne 0 ] && echo "Aborting script..."

  exit "$exit_code"
}

test_arg()
{
  # Used to validate user input
  local arg="$1"
  local argv="$2"

  if [ -z "$argv" ]; then
    if echo "$arg" | grep -qE '^-'; then
      usage "Null argument supplied for option $arg"
    fi
  fi

  if echo "$argv" | grep -qE '^-'; then
    usage "Argument for option $arg cannot start with '-'"
  fi
}

test_path_arg()
{
  # test directory argument
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  if [ ! -e "$argv" ]; then
    usage "Specified output path does not exist."
  fi
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename "$0")|" << EOF
    USAGE

    Mount all partitiions detected on the specified device.

    SYNTAX
            SCRIPT_NAME [OPTIONS] [ARGUMENT]

    ARGUMENT

     device                   The block device containing partitions to mount.

    OPTIONS

     -m, --mountpoint <path>  Set the location to mount device partitions.
     -o, --options <opts>     Configure mount options.

     -v, --verbose            Make the script more verbose.
     -h, --help               Prints this usage.

EOF

    exit_script "$@"
}

VERBOSE=""
VERBOSITY=0

check_verbose()
{
  if [ $VERBOSITY -gt 1 ]; then
    VERBOSE="-v"
  fi
}

# process arguments
#echo num params=$#
#saved=("$@")

MOUNTPOINT=""
MOUNT_OPTS=""

[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -v|--verbose)
      ((VERBOSITY++))
      check_verbose
      i=$((i+1))
      shift
    ;;
    -m|--mountpoint)
      test_path_arg "$1" "$2"
      shift
      MOUNTPOINT="$1"
      shift
    ;;
    -o|--options)
      test_arg "$1" "$2"
      shift
      MOUNT_OPTS="$1"
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      test_arg "$1"
      VOLUME="$1"
      shift
    ;;
  esac
done

if [ -z "${VOLUME}" ]; then
  exit_script 1 "No volume specified."
fi

if [ -z "${MOUNTPOINT}" ]; then
  MOUNTPOINT="${DEFAULT_MOUNTPOINT}"
fi

# Verify mount options have been set
if [ -z "${MOUNT_OPTS}" ]; then
  MOUNT_OPTS="${DEFAULT_MOUNT_OPTS}"
fi
if [ -z "${MOUNT_OPTS}" ]; then
  exit_script 1 "No options specified for 'mount' command."
fi

# check if superuser
if [[ $EUID -ne 0 ]]; then
  echo >&2 "ERROR: This script must be run as root."
  exit 1
fi

# Validate mountpoint and LV path
# TODO: More complete checking to ensure a valid LV path.
if [ ! -e "${VOLUME}" ]; then
  echo >&2 "ERROR: Volume '${VOLUME}' does not exist."
  exit 1
fi
if [ ! -e "${MOUNTPOINT}" ]; then
  mkdir -v -p "${MOUNTPOINT}"
  chmod 700 "${MOUNTPOINT}"
fi

function getSize() {
  re='^[0-9]+$'
  if ! [[ $1 =~ $re ]] ; then
    echo -n "NaN"
    return 1
  fi

  if [ "$1" -lt 1000 ]; then
    echo -n "${1} bytes"
    return 0
  fi

  echo "$1" |  awk '
    function human(x) {
        if (x<1000) {return x} else {x/=1024}
        s="kMGTEPZY";
        while (x>=1000 && length(s)>1)
            {x/=1024; s=substr(s,2)}
        return int(x+0.5) substr(s,1,1)
    }
    {sub(/^[0-9]+/, human($1)); print}'
}

# Determine volume information
BLKID_DESCR=$(blkid "${VOLUME}")
VOLUME_NAME=$(basename "${VOLUME}")
VOLUME_TYPE=$(fdisk -l "${VOLUME}" | grep "Disklabel type:" | awk '{ print $3 }')

if [ -z "${VOLUME_TYPE}" ]; then
  echo >&2 "ERROR: Failed to determine partition scheme for volume '${VOLUME}'."
  exit 1
fi

case ${VOLUME_TYPE} in
    mbr)
        echo "Detected Master Boot Record (MBR) partition table format."
    ;;
    gpt)
        echo "Detected GUID Partition Table (GPT) partition table format."
    ;;
    dos)
        echo "Detected DOS partition table format."
    ;;
    *)
        echo >&2 "ERROR: Unrecognized partition format '${VOLUME_TYPE}'."
        exit 1
    ;;
esac

# Create a new directory for mounting partitions
MOUNTPOINT="${MOUNTPOINT}/${VOLUME_NAME}"
if [ -e "${MOUNTPOINT}" ]; then
  echo >&2 "ERROR: Mount directory '${MOUNTPOINT}' already exists."
  exit 1
fi
mkdir "${MOUNTPOINT}"

# Print a header with some basic information
echo "Mounting ${VOLUME_TYPE} device ${VOLUME} -> ${MOUNTPOINT} (options: '${MOUNT_OPTS}') ..."
echo "${BLKID_DESCR}"

# Backup the partition table
if [ "${VOLUME_TYPE}" == "gpt" ]; then
  if ! gdisk -l "${VOLUME}" | tail -n+9 > "${MOUNTPOINT}/${VOLUME_NAME}-partitions.gdisk" 2>&1; then
    echo >&2 "WARNING: Non-zero exit code from gdisk when trying to dump partitions table for device '${VOLUME}'."
  fi
  if ! sgdisk --backup="${MOUNTPOINT}/${VOLUME_NAME}-partitions-backup.sgdisk" "${VOLUME}" > /dev/null 2>&1; then
    echo >&2 "WARNING: Non-zero exit code from sgdisk when trying to backup partitions table for device '${VOLUME}'."
  fi
else
  if ! fdisk -l "${VOLUME}" > "${MOUNTPOINT}/${VOLUME_NAME}-partitions.fdisk" 2>&1; then
    echo >&2 "WARNING: Non-zero exit code from fdisk when trying to dump partitions table for device '${VOLUME}'."
  fi
  if ! sfdisk --dump "${VOLUME}" > "${MOUNTPOINT}/${VOLUME_NAME}-partitions-backup.sfdisk"; then
    echo >&2 "WARNING: Non-zero exit code from sfdisk when trying to backup partitions table for device '${VOLUME}'."
  fi
fi

# NOTE: util-linux 2.26 supports GPT
#sfdisk -d ${VOLUME} > "${MOUNTPOINT}/partitions-backup-${VOLUME_NAME}.sfdisk"

# Determine mappings that will be generated by kpartx
if ! KPARTX_LIST=$(kpartx -l "${VOLUME}" | awk '{ print $1 }'); then
  echo >&2 "ERROR: Failed to determine kpartx mappings for ${VOLUME}."
  if [ -e "${MOUNTPOINT}" ]; then
    rm -rf "${MOUNTPOINT}"
  fi
  exit 1
fi

declare -a mappings=();
for part in ${KPARTX_LIST}; do
  map="/dev/mapper/${part}"
  mappings=("${mappings[@]}" "${map}")
done

# Create mappings
if ! kpartx -as "${VOLUME}"; then
  echo >&2 "ERROR: Failed to create mappings for ${VOLUME}."
  exit 1
fi

TOTAL_SIZE=0
TOTAL_MOUNTED=0

# Configure mount command line
MOUNT_EXTRA=""
if [ -n "${MOUNT_OPTS}" ]; then
  MOUNT_EXTRA="-o ${MOUNT_OPTS}"
fi
MOUNT_CMD="mount ${MOUNT_EXTRA}"

# Print out mappings
declare -a mounted=();
for ((idx=0;idx<=$((${#mappings[@]}-1));idx++)); do
  map=${mappings[$idx]}
  dev=$(readlink -e "${map}")
  mnt=$(basename "${map}")
  if [ ! -b "$dev" ]; then
    echo >&2 "WARNING: '${map}' does not point to a valid block device."
  fi
  # TODO: Add check for snapshots to make sure origin is not mounted
  if mount | grep -q "${mnt}"; then
    echo >&2 "ERROR: '${map}' is already mounted; aborting..."
    exit 1
  fi

  BLKID=$(blkid "${map}")
  FSTYPE=$(echo "$BLKID" | grep -Po '(?<=TYPE\=\")[A-Za-z0-9\-\_\s]+(?=\")')
  LABEL=$(echo "$BLKID" | grep -Po '(?<=LABEL\=\")[A-Za-z0-9\-\_\s]+(?=\")')
  SIZE=$(blockdev --getsize64 "${map}")

  MNT_PATH="${MOUNTPOINT}/${mnt}"
  if [ -e "${MNT_PATH}" ]; then
    echo >&2 "WARNING: The path '${MNT_PATH}' already exists; skipping..."
  else
    mkdir "${MNT_PATH}"
    if ! MOUNT_OUTPUT=$(${MOUNT_CMD} "${dev}" "${MNT_PATH}" 2>&1); then
      echo >&2 "ERROR: Failed to mount ${map}: ${MOUNT_OUTPUT}"
      rm -rf "${MNT_PATH}"
    else
      ((TOTAL_MOUNTED++))
      TOTAL_SIZE=$((TOTAL_SIZE+SIZE))
      mounted=("${mounted[@]}" "${MNT_PATH}")
      if [ -z "${LABEL}" ]; then
        printf "Mounted %s -> %s (Type: %-6s Size: %-6s)\\n" "${mnt}" "${MNT_PATH}" "${FSTYPE}" "$(getSize "${SIZE}")"
      else
        printf "Mounted %s -> %s (Type: %-6s Size: %-6s Label: %s)\\n" "${mnt}" "${MNT_PATH}" "${FSTYPE}" "$(getSize "${SIZE}")" "${LABEL}"
      fi
    fi
  fi
done

printf "Mounted %i partition(s) totaling %s in size.\\n" ${TOTAL_MOUNTED} "$(getSize ${TOTAL_SIZE})"

exit 0
