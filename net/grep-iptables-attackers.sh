#!/bin/bash
# Greps dropped packets from a system log

LOGPATTERN="/var/log/syslog"

if [ -n "$1" ]; then
  if [ ! -e "$1" ]; then
    echo >&2 "ERROR: The specified log file '$1' does not exist."
    exit 1
  fi
  LOGPATTERN="$1"
fi

function grep_table()
{
  grep "iptables dropped:" "$LOGPATTERN" | while read -r line; do
    src=$(echo "${line}" | grep -Po '(?<=SRC=)([0-9]{1,3}[\.]){3}[0-9]{1,3}(?=\s)')
    dpt=$(echo "${line}" | grep -Po '(?<=DPT=)[0-9]+(?=\s)')
    proto=$(echo "${line}" | grep -Po '(?<=PROTO=)[A-Za-z]+(?=\s)')
    # dst=$(echo "${line}" | grep -Po '(?<=DST=)([0-9]{1,3}[\.]){3}[0-9]{1,3}(?=\s)')
    # mac=$(echo "${line}" | grep -Po '(?<=MAC=)([0-9a-fA-F][0-9a-fA-F]:){5,15}([0-9a-fA-F][0-9a-fA-F])(?=\s)')
    # inface=$(echo "${line}" | grep -Po '(?<=IN=)[A-Za-z0-9\._-]+(?=\s)')

    printf "%-15s\\t%s/%s\\n" "$src" "$dpt" "$proto"
    # printf "%-15s -> %-15s \\t %s/%s\\n" "$src" "$dst" "$dpt" "$proto"
  done
}

function print_report()
{
  output=$(grep_table)
  echo "${output}" | sort -n \
    | uniq -c \
    | sort -rn \
    | head -n 50
}

print_report

exit 0
