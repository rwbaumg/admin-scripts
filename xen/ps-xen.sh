#!/bin/bash
# list xen and qemu processes
# rwb@0x19e.net

procs=$(ps -ef | grep 'xl\|qemu' | grep -v grep)
echo "$procs"
