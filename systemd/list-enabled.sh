#!/bin/bash
# List enabled systemd units

hash systemctl 2>/dev/null || { echo >&2 "You need to install systemd. Aborting."; exit 1; }
hash grep 2>/dev/null || { echo >&2 "You need to install grep. Aborting."; exit 1; }
hash awk 2>/dev/null || { echo >&2 "You need to install awk. Aborting."; exit 1; }

systemctl list-unit-files | grep enabled | awk '{ print $1 }' | sort

exit 0
