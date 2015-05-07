#!/bin/bash
# lists all installed kernels
# (aside from the running version)
# can be used to automate removal of old modules

dpkg -l 'linux-*' | \
sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'
