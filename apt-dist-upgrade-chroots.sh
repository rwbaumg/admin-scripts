#!/bin/bash
# upgrades chroot environments

hash apt 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }
hash schroot 2>/dev/null || { echo >&2 "You need to install schroot. Aborting."; exit 1; }

for chroot in $(schroot -l|awk -F : '{print $2}'); do
    echo "Upgrading '$chroot' chroot ..."
    if ! schroot -q --directory /tmp -c "$chroot" -u root -- sh -c 'apt -qq update && apt -qy dist-upgrade && apt -qy autoremove && apt clean'; then
      echo >&2 "WARNING: Failed to upgrade chroot '$chroot'."
    fi
done

exit 0
