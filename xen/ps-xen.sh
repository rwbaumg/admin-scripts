#!/bin/bash
# list xen and qemu processes
# rwb@0x19e.net

procs=$(ps -ef | grep 'xl\|qemu' | grep -v grep)
if [[ -z "$1" ]]; then
  echo "No processes found."
  exit 1
fi

echo "$procs"
exit 0
