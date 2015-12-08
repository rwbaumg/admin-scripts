#!/bin/bash
# Clean up the /boot partition
# DANGER: This script is dangerous!
# Only run it if you know what you
# are doing.

dpkg -l 'linux-*' \
| sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' \
| xargs sudo apt-get -y purge
