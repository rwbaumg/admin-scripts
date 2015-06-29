#!/bin/bash
# list xen and qemu processes
procs=$(ps -ef | grep 'xl\|qemu' | grep -v grep)
echo "$procs"
