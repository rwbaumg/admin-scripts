#!/bin/bash
# List available serial devices and driver information

for f in /sys/class/tty/*/device/driver; do

  driver_dir="$f"
  serial_dev=$(echo "$f" | grep -Po '(?<=tty\/)[^\/]+(?=\/device)')
  driver_dir=$(readlink -f "$f")
  echo -e "$serial_dev \t -> $driver_dir"

done

exit 0
