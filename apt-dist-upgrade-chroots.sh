#!/bin/bash
# upgrades chroot environments

for chroot in `schroot -l|awk -F : '{print $2}'`; do
    echo "Upgrading '$chroot' chroot ..."
    schroot -q -c $chroot -u root -- sh -c 'apt-get -qq update && apt-get -qy dist-upgrade && apt-get clean'
done
