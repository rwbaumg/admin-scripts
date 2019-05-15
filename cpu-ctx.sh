#!/bin/bash
# Script to examine per-process CPU context switching

MAX_LINES=50
SECONDS=0

check_core_id()
{
  local core="$1"
  if [ -z "${core}" ]; then
    echo >&2 "ERROR: CPU core number cannot be null."
    exit 1
  fi

  re='^[0-9]+$'
  if ! [[ $core =~ $re ]]; then
    echo >&2 "ERROR: '${core}' is not a valid number."
    exit 1
  fi

  core=$((${core}-1))

  if [ ! -e "/sys/bus/cpu/devices/cpu${core}" ]; then
    echo >&2 "ERROR: '$((${core}+1))' is not a valid CPU core number."
    exit 1
  fi
}

function get_ctx_total()
{
  if [ ! -e "/proc/stat" ]; then
    echo >&2 "ERROR: Failed to read file /proc/stat"
    return 1
  fi

  ctxt=$(grep ctxt /proc/stat | awk '{ print $2 }')
  if [ -z "${ctxt}" ]; then
    echo >&2 "ERROR: Failed to read 'ctxt' parameter from /proc/stat"
    return 1
  fi

  echo "${ctxt}"
  return 0
}

function show_core()
{
  if [ -z "$1" ]; then
    echo >&2 "ERROR: No core number specified."
    return 1
  fi

  # filter based on core number
  ps -xao psr,pid,comm | tail -n +2 | sort -k 2nr | uniq | grep -v -P '\s(grep|ps|uniq|sort|tail|head|column|awk)$' \
    | grep -P "^([\s]+)?$1\s" \
    | awk '{printf $2"\t"$3"\t";system("cut -d\" \" -f3 /proc/"$2"/task/"$2"/schedstat 2>/dev/null")}' \
    | sort -k 3nr \
    | column -t \
    | head -n -1 \
    | head -n ${MAX_LINES}

  return 0
}

function show_all()
{
  # look at all cpu cores
  ps -xao pid,comm | tail -n +2 | sort -k 1nr | uniq | grep -v -P '\s(grep|ps|uniq|sort|tail|head|column|awk)$' \
    | awk '{printf $1"\t"$2"\t"; system("cut -d\" \" -f3 /proc/"$1"/task/"$1"/schedstat 2>/dev/null")}' \
    | sort -k 3nr \
    | column -t \
    | head -n -1 \
    | head -n ${MAX_LINES}

  return 0
}

if [ -n "$1" ]; then
  check_core_id "$1"
fi

echo "==================================="
echo "CPU Context Switching (top ${MAX_LINES} PIDs)"
echo "==================================="
echo

total=$(get_ctx_total)
if [ -n "$total" ]; then
  echo -e "Total CTX count:\t$total"
fi
if [ -n "$1" ]; then
  echo -e "Selected CPU core:\t$1"
fi

echo
printf "PID    COMM\t\tCTX\n"
echo "-----------------------------------"
if [ -n "$1" ]; then
  show_core "$1"
else
  show_all
fi
echo "-----------------------------------"

ELAPSED_STRING=$(date -u -d @${SECONDS} +%T)

echo "Elapsed time: ${ELAPSED_STRING}"
echo

exit 0
