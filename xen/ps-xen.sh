#!/bin/bash
# list xen and qemu processes
# [0x19e Networks] rwb@0x19e.net

procs=$(ps -ef | grep 'xl\|qemu\|xen' | grep -v grep | grep -v "$0")
if [[ -z "$procs" ]]; then
  echo "No processes found."
  exit 1
fi

echo "$procs"
exit 0
