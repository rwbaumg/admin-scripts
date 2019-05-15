#!/bin/bash
# Mount temporary storage at the specified mountpoint

# Default size
SIZE_MB=100

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
      echo >&2 "INFO: $@"
    else
      echo "ERROR: $@" 1>&2
    fi
  fi

  # Print 'aborting' string if exit code is not 0
  [ $exit_code -ne 0 ] && echo >&2 "Aborting script..."

  exit $exit_code
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename $0)|" -e "s|DEFAULT_SIZE|${SIZE_MB}|" << EOF
    USAGE

    Mount temporary storage to the specified location.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     mountpoint            The location to mount temporary storage to.

    OPTIONS

     -s, --size <mb>       The desired size (in megabytes).
                           Defaults to DEFAULT_SIZEMB.

     -v, --verbose         Make the script more verbose.
     -h, --help            Prints this usage.

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

test_path()
{
  # test directory argument
  local arg="$1"

  test_arg $arg

  if [ ! -d "$arg" ]; then
    usage "Specified directory does not exist."
  fi

  if find "$arg" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
    usage "The directory '$(readlink -m $arg)' is not empty."
  fi
}

test_number_arg()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  re='^[0-9]+$'
  if ! [[ $argv =~ $re ]]; then
    usage "Value is not a valid number: '$argv'."
  fi

  if ! [ $argv -gt 0 ]; then
    usage "The specified value is less than the minimum (1)."
  fi
}

MOUNTPOINT=""
VERBOSITY=0

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -s|--size)
      test_number_arg "$1" "$2"
      shift
      SIZE_MB=$1
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      if [ -n "${MOUNTPOINT}" ]; then
        usage
      fi
      test_path "$1"
      MOUNTPOINT=$(readlink -m "$1")
      shift
    ;;
  esac
done

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

FREE_RAM=$(awk '/MemFree/ { printf "%i\n", $2/1024 }' /proc/meminfo)
SAFE_SIZE=$((${FREE_RAM}-$((${FREE_RAM}/10))))

if [ $VERBOSITY -gt 0 ]; then
  echo "Mountpoint : ${MOUNTPOINT}"
  echo "RAM size   : ${SIZE_MB}m"
  echo "Free RAM   : ${FREE_RAM}m"
  echo "Usable RAM : ${SAFE_SIZE}m"
  echo "Verbosity  : ${VERBOSITY}"
fi

#if [ ${FREE_RAM} -lt 500 ]; then
#  exit_script 1 "Not enough available memory (free memory: ${FREE_RAM}m)."
#fi
if [ ${SIZE_MB} -gt ${SAFE_SIZE} ]; then
  usage "The requested size (${SIZE_MB}m) is too large for the available memory (${SAFE_SIZE}m)."
fi

echo "Mounting ${SIZE_MB}m of RAM to ${MOUNTPOINT} ..."

MOUNT_EXTRA_ARGS=""
if [ $VERBOSITY -gt 0 ]; then
  MOUNT_EXTRA_ARGS="-v"
fi

if ! mount ${MOUNT_EXTRA_ARGS} -t tmpfs tmpfs ${MOUNTPOINT} -o size=${SIZE_MB}m; then
  exit_script 1 "Failed to mount tmpfs storage."
fi

exit_script 0
