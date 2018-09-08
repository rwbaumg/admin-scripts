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

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo >&2 "This script must be run as root."
   exit 1
fi

# Enumerate logical volumes
i=1
IFS=$'\n'; for lv in `lvs -o lv_name,lv_path,lv_attr | tail -n+2`; do
  name=$(echo "$lv" | awk '{ print $1 }')
  path=$(echo "$lv" | awk '{ print $2 }')
  attr=$(echo "$lv" | awk '{ print $3 }')

  voltype=${attr:0:1}
  perm=${attr:1:1}
  alloc=${attr:2:1}
  minor=${attr:3:1}
  state=${attr:4:1}
  device=${attr:5:1}
  tgttype=${attr:6:1}
  zero=${attr:7:1}
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
    ;;
    S)
    # Merging snapshot
    type_desc="Merging snapshot"
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

  # Minor
  minor_desc=""
  case "$minor" in
    m)
    # Fixed minor
    minor_desc="Fixed minor"
    ;;
    -)
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

  # Device
  device_desc=""
  case "$device" in
    o)
    # Open
    device_desc="Open"
    if [ "$SKIP_OPEN_DEVS" == "true" ]; then
      include="false"
    fi
    ;;
    X)
    # Unknown
    device_desc="Unknown"
    ;;
    -)
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

  # Zero
  zero_desc=""
  case "$zero" in
    z)
    # Zero
    zero_desc="Newly-allocated data blocks are overwritten with blocks of zeroes before use"
    ;;
    -)
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

  echo "Entry $i"
  echo "------------------------------"
  echo "Name: $name"
  echo "Path: $path"
  echo "Attr: $attr"
  echo
  #echo "  Volume Type: $voltype"
  #echo "  Permissions: $perm"
  #echo "   Allocation: $alloc"
  #echo "        Minor: $minor"
  #echo "        State: $state"
  #echo "       Device: $device"
  #echo "  Target type: $tgttype"
  #echo "         Zero: $zero"
  #echo "       Health: $health"
  #echo "         Skip: $skip"
  #echo
  echo "  Volume Type: $type_desc"
  echo "  Permissions: $perm_desc"
  echo "   Allocation: $alloc_desc"
  echo "        Minor: $minor_desc"
  echo "        State: $state_desc"
  echo "       Device: $device_desc"
  echo "  Target type: $tgttype_desc"
  echo "         Zero: $zero_desc"
  echo "       Health: $health_desc"
  echo "         Skip: $skip_desc"
  echo "EOF"
  echo

  ((i++))

  fi
done

exit 0
