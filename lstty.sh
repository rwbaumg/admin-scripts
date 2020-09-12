#!/bin/bash
# List available serial devices and driver information

hash grep 2>/dev/null || { echo >&2 "You need to install grep. Aborting."; exit 1; }
hash sort 2>/dev/null || { echo >&2 "You need to install sort. Aborting."; exit 1; }

function get_devices() {
  for f in /sys/class/tty/*/device/driver; do

    driver_dir="$f"
    serial_dev=$(echo "$f" | grep -Po '(?<=tty\/)[^\/]+(?=\/device)')
    driver_dir=$(readlink -f "$f")
    echo -e "$serial_dev \t -> $driver_dir"

  done
}

OUTPUT=$(get_devices)

echo "${OUTPUT}" | sort -V

exit 0
