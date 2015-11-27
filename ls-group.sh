#!/bin/bash
# list all members of the specified group

hash awk 2>/dev/null || { echo >&2 "You need to install awk. Aborting."; exit 1; }

if [[ -z "$1" ]]; then
  echo "Usage: $0 <group>" >&2
  exit 1
fi

GROUP_NAME="$1"

MEMBERS=$(awk -F':' "/^$GROUP_NAME/{print $4}" /etc/group)

echo $MEMBERS
