#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

ZONE_TAB="/usr/share/zoneinfo/zone.tab"

if [[ -z "$1" ]]; then
  echo "Usage: $0 <tz_name>"
  exit 1
fi

TZ_NAME=$(cat $ZONE_TAB | grep -i "$1" | awk '{print $3}')
if [[ -z "$TZ_NAME" ]]; then
  echo "ERROR: Failed to find timezone for '$1'"
  exit 1
fi

echo $TZ_NAME | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata
