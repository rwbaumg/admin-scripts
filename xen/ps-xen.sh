#!/bin/bash
# list xen and qemu processes
# [0x19e Networks] rwb@0x19e.net

procs=$(pgrep -af 'xl|qemu|xen' | grep -v "$0")
if [[ -z "$procs" ]]; then
  echo "No processes found."
  exit 1
fi

echo "$procs"
exit 0
