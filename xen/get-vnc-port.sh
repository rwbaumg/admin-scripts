#!/bin/bash
if [ "$1" = "" ]
then
  echo "Usage: $0 <xen guest name>"
  exit
fi
name=$1
pid=$(ps -ef | grep "qemu" | grep "name $name" | awk '{ print $2}')

if [[ -z "$pid" ]]; then
  echo "ERROR: Failed to find qemu pid for '$name'"
  exit 1
fi

lsof -nPi | grep "$pid"
