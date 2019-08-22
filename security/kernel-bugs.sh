#!/bin/bash
# List known mitigations for CPU bugs via sysfs

if [ ! -e "/sys/devices/system/cpu/vulnerabilities" ]; then
  echo "ERROR: Kernel does not support listing known bugs." >&2
  exit 1
fi

if ! head -n -0 /sys/devices/system/cpu/vulnerabilities/*; then
  exit 1
fi

exit 0
