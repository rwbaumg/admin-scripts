#!/bin/bash
# upgrades chroot environments

hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }
hash apt 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }
hash schroot 2>/dev/null || { echo >&2 "You need to install schroot. Aborting."; exit 1; }

APT_CMD="apt-get"

# Ensure sudo privileges for the current user if not running as root.
if [[ $EUID -ne 0 ]]; then
  echo "NOTICE: Running as user $USER; sudo privileges required."
  if ! sudo echo "" > /dev/null 2>&1; then
    echo >&2 "ERROR: Must have sudo privileges to modify configuration files."
    exit 1
  fi
fi

for chroot in $(schroot -l|awk -F : '{print $2}'); do
    echo "Upgrading '${chroot}' chroot ..."
    if ! sudo schroot -q --directory /tmp -c "${chroot}" -u root -- sh -c "${APT_CMD} -qq update && ${APT_CMD} -qy dist-upgrade && ${APT_CMD} -qy autoremove && ${APT_CMD} clean"; then
      echo >&2 "WARNING: Failed to upgrade chroot '${chroot}'."
    fi
done

exit 0
