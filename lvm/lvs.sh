#!/bin/bash
#
# -=[0x19e Networks]=-
#
# Simple Logical Volume Manager (LVM) enumeration script.
# Demonstrates processing logical volume properties.
#
# Robert W. Baumgartner <rwb@0x19e.net>
#
SKIP_OPEN_DEVS="false"
SKIP_SNAPSHOTS="false"
ALLOW_FUZZFILT="false"

hash lvs 2>/dev/null || { echo >&2 "You need to install lvm2. Aborting."; exit 1; }

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

    Lists available Logical Volume Manager (LVM) volumes.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS

     -p, --perm <value>           Permissions filter.
     -a, --alloc <value>          Allocation filter.
     -s, --state <value>          State filter.
     -m, --volume-type <value>    Volume type filter.
     -t, --target-type <value>    Target type filter.

     --device-open                Only list volumes marked "Open".
     --device-closed              Only list volumes NOT marked "Open".
     --zero-enabled               Only list volumes with "Zero" enabled.
     --zero-disabled              Only list volumes with "Zero" disabled.
     --minor-enabled              Only list volumes using fixed minor.
     --minor-disabled             Only list volumes WITHOUT fixed minor.
     --ignore-snapshots           Ignore snapshot volumes.

     -v, --verbose                Make the script more verbose.
     -h, --help                   Prints this usage.

    EXAMPLES

     - To list all logical volumes:

        ./SCRIPT_NAME

     - To list all logical volumes not currently active.

        ./SCRIPT_NAME --device-closed

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

test_string()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  re='^[A-Za-z\-]+$'
  if ! [[ $argv =~ $re ]] ; then
    usage "Argument must be a valid character string."
  fi
}

test_char()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  re='^[A-Za-z\-]+$'
  if ! [[ $argv =~ $re ]] ; then
    usage "Argument must be a valid character string."
  fi

  if [ ${#argv} -ne 1 ]; then
    usage "Argument must be a single character."
  fi
}

VERBOSITY=0
VERBOPT=""
check_verbose()
{
  if [ $VERBOSITY -gt 1 ]; then
    VERBOPT="-v"
  fi
}

function checkInclude() {
  local filter="$1"
  local value="$2"
  local desc="$3"

  if [ ! -z "${filter}" ]; then
    if [ ${#filter} -eq 1 ]; then
      if ! [ "$value" == "${filter}" ]; then
        echo "false"
      else
        echo "true"
      fi
    elif [ "${ALLOW_FUZZFILT}" == "true" ]; then
      match=$(echo "${desc}" | grep -i "${filter}")
      if [ -z "${match}" ]; then
        if [ $VERBOSITY -gt 1 ]; then
          echo >&2 "Value '${value}' filtered by '${filter}'."
        fi
        echo "false"
      else
        echo "true"
      fi
    fi
  else
    echo "true"
  fi
}

PERM_FILTER=""
ALLOC_FILTER=""
STATE_FILTER=""
VOLTYPE_FILTER=""
TGTTYPE_FILTER=""

DEVICE_OPEN=""
ZERO_ENABLED=""
MINOR_ENABLED=""
IGNORE_SNAPSHOTS=""

# process arguments
#[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -p|--perm)
      test_char "$1" "$2"
      shift
      PERM_FILTER="$1"
      shift
    ;;
    -a|--alloc)
      test_char "$1" "$2"
      shift
      ALLOC_FILTER="$1"
      shift
    ;;
    -s|--state)
      test_char "$1" "$2"
      shift
      STATE_FILTER="$1"
      shift
    ;;
    -m|--volume-type)
      test_char "$1" "$2"
      shift
      VOLTYPE_FILTER="$1"
      shift
    ;;
    -t|--target-type)
      test_char "$1" "$2"
      shift
      TGTTYPE_FILTER="$1"
      shift
    ;;
    --device-open)
      if [ ! -z "${DEVICE_OPEN}" ]; then
        usage "Conflicting or duplicate option(s) specified."
      fi
      DEVICE_OPEN="true"
      shift
    ;;
    --device-closed)
      if [ ! -z "${DEVICE_OPEN}" ]; then
        usage "Conflicting or duplicate option(s) specified."
      fi
      DEVICE_OPEN="false"
      shift
    ;;
    --zero-enabled)
      if [ ! -z "${ZERO_ENABLED}" ]; then
        usage "Conflicting or duplicate option(s) specified."
      fi
      ZERO_ENABLED="true"
      shift
    ;;
    --zero-disabled)
      if [ ! -z "${ZERO_ENABLED}" ]; then
        usage "Conflicting or duplicate option(s) specified."
      fi
      ZERO_DISABLED="false"
      shift
    ;;
    --minor-enabled)
      if [ ! -z "${MINOR_ENABLED}" ]; then
        usage "Conflicting or duplicate option(s) specified."
      fi
      MINOR_ENABLED="true"
      shift
    ;;
    --minor-disabled)
      if [ ! -z "${MINOR_ENABLED}" ]; then
        usage "Conflicting or duplicate option(s) specified."
      fi
      MINOR_ENABLED="false"
      shift
    ;;
    --ignore-snapshots)
      if [ ! -z "${IGNORE_SNAPSHOTS}" ]; then
        usage "Conflicting or duplicate option(s) specified."
      fi
      IGNORE_SNAPSHOTS="true"
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
    -vvv)
      ((VERBOSITY++))
      ((VERBOSITY++))
      ((VERBOSITY++))
      check_verbose
      shift
    ;;
    -vvvv)
      ((VERBOSITY++))
      ((VERBOSITY++))
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

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo >&2 "This script must be run as root."
   exit 1
fi

#if [ $VERBOSITY -gt 0 ]; then
#fi

# Enumerate logical volumes
i=1
IFS=$'\n'; for lv in $(lvs -o lv_name,lv_path,lv_attr | tail -n+2); do
  name=$(echo "$lv" | awk '{ print $1 }')
  path=$(echo "$lv" | awk '{ print $2 }')
  attr=$(echo "$lv" | awk '{ print $3 }')
  blkdev=$(readlink -f "${path}")
  type=$(file -s "${blkdev}")

  voltype=${attr:0:1}
  perm=${attr:1:1}
  alloc=${attr:2:1}
  minor=${attr:3:1}
  state=${attr:4:1}
  device=${attr:5:1}
  tgttype=${attr:6:1}
  zero=${attr:7:1}

  # NOTE: Attributes after this point depend on lvs version
  health=${attr:8:1}
  skip=${attr:9:1}

  include="true"

  # Volume type
  type_desc=""
  case "$voltype" in
    C)
    # Cache
    type_desc="Cache"
    ;;
    m)
    # Mirrored
    type_desc="Mirrored"
    ;;
    M)
    # Mirrored w/o initial sync
    type_desc="Mirrored w/o initial sync"
    ;;
    o)
    # Origin
    type_desc="Origin"
    ;;
    O)
    # Origin w/ merging snapshot
    type_desc="Origin w/ merging snapshot"
    ;;
    r)
    # RAID
    type_desc="RAID"
    ;;
    R)
    # RAID w/o initial sync
    type_desc="RAID w/o initial sync"
    ;;
    s)
    # Snapshot
    type_desc="Snapshot"
    if [ "$SKIP_SNAPSHOTS" == "true" ]; then
      include="false"
    fi
    if [ "$IGNORE_SNAPSHOTS" == "true" ]; then
      include="false"
    fi
    ;;
    S)
    # Merging snapshot
    type_desc="Merging snapshot"
    #if [ "$IGNORE_SNAPSHOTS" == "true" ]; then
    #  include="false"
    #fi
    #if [ "$SKIP_SNAPSHOTS" == "true" ]; then
    #  include="false"
    #fi
    ;;
    p)
    # pvmove
    type_desc="pvmove"
    ;;
    v)
    # Virtual
    type_desc="Virtual"
    ;;
    i)
    # Mirror or RAID image
    type_desc="Mirror or RAID image"
    ;;
    I)
    # Mirror or RAID image out-of-sync
    type_desc="Mirror or RAID image out-of-sync"
    ;;
    l)
    # Mirror log device
    type_desc="Mirror log device"
    ;;
    c)
    # Under conversion
    type_desc="Under conversion"
    ;;
    V)
    # Thin volume
    type_desc="Thin volume"
    ;;
    t)
    # Thin pool
    type_desc="Thin pool"
    ;;
    T)
    # Thin pool data
    type_desc="Thin pool data"
    ;;
    e)
    # raid or pool m(e)tadata or pool metadata spare
    type_desc="RAID or pool metadata or pool metadata spare"
    ;;
    -)
    type_desc="N/A"
    ;;
  esac
  # Check filter
  if [ "${include}" == "true" ]; then
    include=$(checkInclude "${VOLTYPE_FILTER}" "${voltype}" "${type_desc}")
  fi

  # Permissions
  perm_desc=""
  case "$perm" in
    w)
    # Writeable
    perm_desc="Writeable"
    ;;
    r)
    # Read-only
    perm_desc="Read-Only"
    ;;
    R)
    # Read-only activation of non-read-only volume
    perm_desc="Read-only activation of non-read-only volume"
    ;;
    -)
    perm_desc="N/A"
    ;;
  esac
  # Check filter
  if [ "${include}" == "true" ]; then
    include=$(checkInclude "${PERM_FILTER}" "${perm}" "${perm_desc}")
  fi

  # Allocation
  alloc_desc=""
  case "$alloc" in
    a|A)
    # Anywhere
    alloc_desc="Anywhere"
    ;;
    c|C)
    # Contiguous
    alloc_desc="Contiguous"
    ;;
    i|I)
    # Inherited
    alloc_desc="Inherited"
    ;;
    l|L)
    # Cling
    alloc_desc="Cling"
    ;;
    n|N)
    # Normal
    alloc_desc="Normal"
    ;;
    -)
    alloc_desc="N/A"
    ;;
  esac
  # Check filter
  if [ "${include}" == "true" ]; then
    include=$(checkInclude "${ALLOC_FILTER}" "${alloc}" "${alloc_desc}")
  fi

  # Minor
  minor_desc=""
  case "$minor" in
    m)
    # Fixed minor
    if [ "${MINOR_ENABLED}" == "false" ]; then
      include="false"
    fi
    minor_desc="Fixed minor"
    ;;
    -)
    if [ "${MINOR_ENABLED}" == "true" ]; then
      include="false"
    fi
    minor_desc="N/A"
    ;;
  esac

  # State
  state_desc=""
  case "$state" in
    a)
    # Active
    state_desc="Active"
    ;;
    s)
    # Suspended
    state_desc="Suspended"
    ;;
    I)
    # Invalid snapshot
    state_desc="Invalid snapshot"
    ;;
    S)
    # Invalid suspended snapshot
    state_desc="Invalid suspended snapshot"
    ;;
    m)
    # Snapshot merge failed
    state_desc="Snapshot merge failed"
    ;;
    M)
    # Suspended snapshot merge failed
    state_desc="Suspended snapshot merge failed"
    ;;
    d)
    # Mapped device present without tables
    state_desc="Mapped device present without tables"
    ;;
    i)
    # Mapped device present with inactive table
    state_desc="Mapped device present with inactive table"
    ;;
    X)
    # Unknown
    state_desc="Unknown"
    ;;
    -)
    state_desc="N/A"
    ;;
  esac
  # Check filter
  if [ "${include}" == "true" ]; then
    include=$(checkInclude "${STATE_FILTER}" "${state}" "${state_desc}")
  fi

  # Device
  device_desc=""
  case "$device" in
    o)
    # Open
    device_desc="Open"
    if [ "$SKIP_OPEN_DEVS" == "true" ]; then
      include="false"
    fi
    if [ "${DEVICE_OPEN}" == "false" ]; then
      include="false"
    fi
    ;;
    X)
    # Unknown
    if [ "${DEVICE_OPEN}" == "true" ]; then
      include="false"
    fi
    device_desc="Unknown"
    ;;
    -)
    if [ "${DEVICE_OPEN}" == "true" ]; then
      include="false"
    fi
    device_desc="N/A"
    ;;
  esac

  # Target type
  tgttype_desc=""
  case "$tgttype" in
    C)
    # Cache
    tgttype_desc="Cache"
    ;;
    m)
    # Mirror
    tgttype_desc="Mirror"
    ;;
    r)
    # RAID
    tgttype_desc="RAID"
    ;;
    s)
    # Snapshot
    tgttype_desc="Snapshot"
    ;;
    t)
    # Thin
    tgttype_desc="Thin"
    ;;
    u)
    # Unknown
    tgttype_desc="Unknown"
    ;;
    v)
    # Virtual
    tgttype_desc="Virtual"
    ;;
    -)
    tgttype_desc="N/A"
    ;;
  esac
  # Check filter
  if [ "${include}" == "true" ]; then
    include=$(checkInclude "${TGTTYPE_FILTER}" "${tgttype}" "${tgttype_desc}")
  fi

  # Zero
  zero_desc=""
  case "$zero" in
    z)
    # Zero
    if [ "${ZERO_ENABLED}" == "false" ]; then
      include="false"
    fi
    zero_desc="Newly-allocated data blocks are overwritten with blocks of zeroes before use"
    ;;
    -)
    if [ "${ZERO_ENABLED}" == "true" ]; then
      include="false"
    fi
    zero_desc="N/A"
    ;;
  esac

  # Health
  health_desc=""
  case "$health" in
    p)
    # Partial
    health_desc="Partial"
    ;;
    r)
    # Refresh needed
    health_desc="Refresh needed"
    ;;
    m)
    # Mismatches exist
    health_desc="Mismatches exist"
    ;;
    w)
    # Writemostly
    health_desc="Writemostly"
    ;;
    X)
    # Unknown
    health_desc="Unknown"
    ;;
    -)
    health_desc="N/A"
    ;;
  esac

  # Skip
  skip_desc=""
  case "$skip" in
    k)
    # Skip activation
    skip_desc="Volume is flagged to be skipped during activation"
    ;;
    -)
    skip_desc="N/A"
    ;;
  esac

  if [ "$include" == "true" ]; then

  if [ $VERBOSITY -gt 0 ]; then
  echo "Entry $i"
  echo "------------------------------"
  echo "Name: $name"
  echo "Path: $path"
  echo "Link: $blkdev"
  echo "Attr: $attr"
  echo
  if [ $VERBOSITY -gt 2 ]; then
  echo "  Volume Type: $voltype"
  echo "  Permissions: $perm"
  echo "   Allocation: $alloc"
  echo "        Minor: $minor"
  echo "        State: $state"
  echo "       Device: $device"
  echo "  Target type: $tgttype"
  echo "         Zero: $zero"
  # NOTE: Health & Skip depend on LVS version
  #echo "       Health: $health"
  #echo "         Skip: $skip"
  echo
  fi
  if [ $VERBOSITY -gt 1 ]; then
  echo "  Volume Type: $type_desc"
  echo "  Permissions: $perm_desc"
  echo "   Allocation: $alloc_desc"
  echo "        Minor: $minor_desc"
  echo "        State: $state_desc"
  echo "       Device: $device_desc"
  echo "  Target type: $tgttype_desc"
  echo "         Zero: $zero_desc"
  # NOTE: Health & Skip depend on LVS version
  #echo "       Health: $health_desc"
  #echo "         Skip: $skip_desc"
  echo
  fi
  if [ $VERBOSITY -gt 3 ]; then
  echo "$type"
  echo
  fi
  echo "EOF"
  echo
  else
  echo "${path}"
  fi

  ((i++))

  fi
done

exit 0
