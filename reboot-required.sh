#!/bin/bash
# checks if the system is pending a reboot

if [ ! -e /etc/cron.daily/update-notifier-common ]; then
  echo >&2 "This script depends on update-notifier-common."
  exit 1
fi

if [ -f /var/run/reboot-required ]; then
  cat /var/run/reboot-required
  exit 0
fi

exit 1
