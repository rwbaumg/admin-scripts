#!/bin/bash
# upgrades chroot environments

hash apt-get 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }
hash schroot 2>/dev/null || { echo >&2 "You need to install schroot. Aborting."; exit 1; }

for chroot in `schroot -l|awk -F : '{print $2}'`; do
    echo "Upgrading '$chroot' chroot ..."
    schroot -q -c $chroot -u root -- sh -c 'apt-get -qq update && apt-get -qy dist-upgrade && apt-get clean'
done
