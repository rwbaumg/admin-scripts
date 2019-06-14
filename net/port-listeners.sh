#!/bin/bash
# prints a list of processes listening on the specified port

# get the port number
port=$1

# configure headers
no_headers=0

# check for required arguments
if [[ -z "$1" ]]; then
  echo "Usage: $0 <port>" >&2
  exit 1
fi

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

# validate port number
re='^[0-9]+$'
if ! [[ $port =~ $re ]] ; then
  echo >&2 "ERROR: '$port' is not a valid port number."
  exit 1
fi

# note: lsof requires root to identify procs
pid=$(lsof -Pan -i tcp -i udp | grep ":$port"|tr -s " " | cut -d" " -f2)
if [[ -z "$pid" ]]; then
  echo >&2 "No processes found listening on port $port."
  exit 1
fi

if [ "${no_headers}" -eq 1 ]; then
  ps -o user,pid,command --sort=pid --pid "${pid//$'\n'/ }" --no-headers
else
  ps -o user,pid,command --sort=pid --pid "${pid//$'\n'/ }"
fi

exit 0
