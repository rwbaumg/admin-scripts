#!/bin/bash
# checks if the system is pending a reboot

if [ ! -e /etc/apt/apt.conf.d/50unattended-upgrades ]; then
  echo >&2 "This script depends on the 'unattended-upgrades' package."
  exit 1
fi

if [ -f /var/run/reboot-required ]; then
  cat /var/run/reboot-required
  exit 0
fi

exit 1
