#!/bin/bash
# checks if the system is pending a reboot

if [ -f /var/run/reboot-required ]; then
    cat /var/run/reboot-required
    exit 0
fi
exit 1
