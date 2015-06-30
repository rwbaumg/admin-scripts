#!/bin/bash

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

if [ "$1" = "" ]; then
  echo "Usage: $0 <domain name>" >&2
  exit 1
fi

NAME=$1
PID=$(ps -ef | grep "qemu" | grep "name $NAME" | awk '{ print $2}')

if [[ -z "$PID" ]]; then
  echo "ERROR: Failed to find qemu pid for '$NAME'" >&2
  exit 1
fi

# get the port number
PORT=$(lsof -nPi | grep "$PID" | awk '{print $9}' | awk -F":" '{print $2}')

echo $PORT
