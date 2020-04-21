#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <partition>"
  exit 1
fi

# check if superuser
if [[ $EUID -ne 0 ]]; then
  echo >&2 "This script must be run as root."
  exit 1
fi

function showInfo() {
        if [ -z "$1" ]; then
                echo >&2 "ERROR: No device specified."
                return 1
        fi

        if ! output=$(tune2fs -l "$1"); then
                return 1
        fi

        if ! last=$(echo "$output" | grep Last\ c); then
                return 1
        fi
        if ! count=$(echo "$output" | grep Mount); then
                return 1
        fi
        if ! max=$(echo "$output" | grep Max); then
                return 1
        fi

        echo "$last"
        echo "$count"
        echo "$max"

        return 0
}

if ! showInfo "$1"; then
  exit 1
fi

exit 0
