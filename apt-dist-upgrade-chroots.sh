#!/bin/bash
# upgrades chroot environments

hash apt 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }
hash schroot 2>/dev/null || { echo >&2 "You need to install schroot. Aborting."; exit 1; }

APT_CMD="apt-get"

for chroot in $(schroot -l|awk -F : '{print $2}'); do
    echo "Upgrading '${chroot}' chroot ..."
    if ! schroot -q --directory /tmp -c "${chroot}" -u root -- sh -c "${APT_CMD} -qq update && ${APT_CMD} -qy dist-upgrade && ${APT_CMD} -qy autoremove && ${APT_CMD} clean"; then
      echo >&2 "WARNING: Failed to upgrade chroot '${chroot}'."
    fi
done

exit 0
