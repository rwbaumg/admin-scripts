#!/bin/bash
# locks GNOME by clearing any cached credentials

hash gnome-keyring-daemon 2>/dev/null || { echo >&2 "You need to install gnome-keyring. Aborting."; exit 1; }

printf "Locking GNOME keyring ..."

# clear cached keys from gnome-keyring
gnome-keyring-daemon -r -d > /dev/null 2>&1

printf "done.\n"

exit 0
