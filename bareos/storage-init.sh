#!/bin/bash
#
# -=[ 0x19e Networks ]=-
#
# Initialize tape storage for use with Bareos.
#
# Robert W. Baumgartner <rwb@0x19e.net>

# Default options
START_INDEX=1
INIT_COUNT=0
POOL="Scratch"
DRIVE_IDX=0
DEV_DRIVE="/dev/nst0"
DEV_CHNGR="/dev/sg1"
MTX_SCRIPT="/usr/lib/bareos/scripts/mtx-changer"

# Check for required commands
hash mt 2>/dev/null || { echo >&2 "You need to install mt-st. Aborting."; exit 1; }
hash bconsole 2>/dev/null || { echo >&2 "You need to install bareos-bconsole. Aborting."; exit 1; }

function InitTape()
{
  local tape_num=$1
  if ! [[ "${tape_num}" =~ ^-?[0-9]+$ ]]; then
    echo >&2 "ERROR: '${tape_num}' is not a valid index number."
    exit 1
  fi

  if ! ${MTX_SCRIPT} ${DEV_CHNGR} load ${tape_num} ${DEV_DRIVE} ${DRIVE_IDX}; then
    echo >&2 "ERROR: Failed to load tape ${tape_num} to drive ${DRIVE_IDX} (${DEV_DRIVE})."
    exit 1
  fi

  if [ $VERBOSITY -gt 0 ]; then
    echo "Writing EOF to start of tape ${tape_num} on drive ${DRIVE_IDX} (${DEV_DRIVE})..."
  fi

  if ! mt -f ${DEV_DRIVE} rewind; then
    echo >&2 "ERROR: Rewind tape ${tape_num} on drive ${DRIVE_IDX} (${DEV_DRIVE}) failed."
    exit 1
  fi

  if ! mt -f ${DEV_DRIVE} weof; then
    echo >&2 "ERROR: Writing EOF to start of tape ${tape_num} failed on drive ${DRIVE_IDX} (${DEV_DRIVE})."
    exit 1
  fi

  if [ $VERBOSITY -gt 0 ]; then
    echo "Writing label for pool '${POOL}' to tape ${tape_num} on drive ${DRIVE_IDX} (${DEV_DRIVE})..."
  fi

  if ! $(echo "label barcodes pool=${POOL} drive=${DRIVE_IDX} slot=${tape_num} ${ENCRYPT} yes" | bconsole); then
    echo >&2 "ERROR: Failed to label tape ${tape_num} on drive ${DRIVE_IDX} (${DEV_DRIVE})."
    exit 1
  fi

  if ! ${MTX_SCRIPT} ${DEV_CHNGR} unload ${tape_num} ${DEV_DRIVE} ${DRIVE_IDX}; then
    echo >&2 "ERROR: Failed to unload tape ${tape_num} from drive ${DRIVE_IDX} (${DEV_DRIVE})."
    exit 1
  fi
}

exit_script()
{
    # Default exit code is 1
    local exit_code=1
    local re var

    re='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'
    if echo "$1" | grep -qE "$re"; then
        exit_code=$1
        shift
    fi

    re='[[:alnum:]]'
    if echo "$@" | grep -iqE "$re"; then
        if [ $exit_code -eq 0 ]; then
            echo "INFO: $@"
        else
            echo "ERROR: $@" 1>&2
        fi
    fi

    # Print 'aborting' string if exit code is not 0
    [ $exit_code -ne 0 ] && echo "Aborting script..."

    exit $exit_code
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename $0)|" << EOF
    USAGE

    Initializes one or more LTO tape storage elements for Bareos.

    Existing tape labels are overwritten enabling tape re-use.
    This script starts at storage element 1 and continues until
    'count' elements are initialized.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS

     -c, --count <value>         The number of storage elements
                                 to initialize.
     -s, --start <value>         The index to start initializing
                                 elements at (default: 1).
     -p, --pool <value>          The name of the pool to label
                                 elements for (default: Scratch).
     -a, --autochanger <value>   The full path to the autochanger
                                 device (default: /dev/sg1).
     -d, --drive <value>         The full path to the tape drive
                                 device (default: /dev/nst0).
     -i, --drive-index <value>   The index of the tape drive (default: 0).

     -e, --encrypt               Label the element to use LTO hardware
                                 encryption.

     -v, --verbose               Make the script more verbose.
     -h, --help                  Prints this usage.

EOF

    exit_script $@
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

test_number()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  re='^[0-9]+$'
  if ! [[ $argv =~ $re ]] ; then
    usage "Argument must be numeric"
  fi
}

# Check permission
if ! $(bconsole -t > /dev/null 2>&1); then
  usage "User $USER does not have permission to initialize storage elements."
fi

VERBOSITY=0
VERBOPT=""
check_verbose()
{
  if [ $VERBOSITY -gt 1 ]; then
    VERBOPT="-v"
  fi
}

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -c|--count)
      test_number "$1" "$2"
      shift
      INIT_COUNT="$1"
      shift
    ;;
    -s|--start)
      test_number "$1" "$2"
      shift
      START_INDEX="$1"
      shift
    ;;
    -p|--pool)
      test_arg "$1" "$2"
      shift
      POOL="$1"
      shift
    ;;
    -i|--drive-index)
      test_number "$1" "$2"
      shift
      DRIVE_IDX="$1"
      shift
    ;;
    -d|--drive)
      test_arg "$1" "$2"
      shift
      DEV_DRIVE="$1"
      shift
    ;;
    -a|--autochanger)
      test_arg "$1" "$2"
      shift
      DEV_CHNGR="$1"
      shift
    ;;
    -e|--encrypt)
      ENCRYPT="encrypt"
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      check_verbose
      shift
    ;;
    -vv)
      ((VERBOSITY++))
      ((VERBOSITY++))
      check_verbose
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      # unknown option
      usage "Unknown option: ${1}."
    ;;
  esac
done

if [ ${START_INDEX} -lt 1 ]; then
  usage "Start index must be greater than or equal to 1."
fi
if [ ${INIT_COUNT} -lt 1 ]; then
  usage "Count must be greater than or equal to 1."
fi

if [ ! -e "${MTX_SCRIPT}" ]; then
  echo >&2 "ERROR: Autochanger script '${MTX_SCRIPT}' does not exist."
  echo >&2 "Make sure the bareos-storage-tape package is installed."
  exit_script
fi

echo "Running storage initialization for ${INIT_COUNT} element(s), starting at index ${START_INDEX}..."

if [ ! -z "${ENCRYPT}" ]; then
  echo "Hardware LTO encryption enabled."
fi

if [ $VERBOSITY -gt 0 ]; then
  echo "Using autochanger ${DEV_CHNGR}"
  echo "Using tape drive ${DEV_DRIVE}"
fi

# print options
if [ $VERBOSITY -gt 1 ]; then
  echo >&2
  echo >&2 "============================="
  echo >&2 "Initialization options"
  echo >&2 "============================="
  echo >&2 "START INDEX   = ${START_INDEX}"
  echo >&2 "ELEMENT COUNT = ${INIT_COUNT}"
  echo >&2 "STORAGE POOL  = ${POOL}"
  echo >&2 "AUTOCHANGER   = ${DEV_CHNGR}"
  echo >&2 "DRIVE DEVICE  = ${DEV_DRIVE}"
  echo >&2 "DRIVE INDEX   = ${DRIVE_IDX}"
  if [ ! -z "${ENCRYPT}" ]; then
  echo >&2 "ENCRYPTION    = enabled"
  else
  echo >&2 "ENCRYPTION    = disabled"
  fi
  echo >&2 "============================="
  echo >&2
fi

X=0
for ((idx=1;idx<=${INIT_COUNT};idx++)); do
  CURRENT_ELEMENT=$(((idx + START_INDEX) - 1))

  if [ $VERBOSITY -gt 0 ]; then
    echo "Initializing storage element #${CURRENT_ELEMENT}..."
  fi

  InitTape ${CURRENT_ELEMENT}
  ((X++))

  if [ $VERBOSITY -gt 1 ]; then
    echo "Storage element #${CURRENT_ELEMENT} labeled for pool '${POOL}'."
  fi
done

echo "${X} storage element(s) initialized for pool '${POOL}'."

exit_script 0
