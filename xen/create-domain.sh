#!/bin/bash
# create a new xen domain
# this script also checks for post-up scripts
# following the format '<domain_name>.sh'
# rwb@0x19e.net

# check if xl command exists
hash xl 2>/dev/null || { echo >&2 "You need to install xen-tools. Aborting."; exit 1; }

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

if [ -z "$1"  ]; then
  echo "Usage: $0 <domain name>" >&2
  exit 1
fi

DOMAIN_NAME="$1"
DOMAIN_CONF="/etc/xen/$DOMAIN_NAME.cfg"
POST_SCRIPT="/etc/xen/$DOMAIN_NAME.sh"

if [ ! -f "$DOMAIN_CONF" ]; then
  echo "Failed to find domain configuration $DOMAIN_CONF" >&2
  exit 1
fi

# todo: check if domain is already running

# create the new domain
xl create $DOMAIN_CONF

if [ -x "$POST_SCRIPT" ]; then
  echo "Running post-script $POST_SCRIPT ..."
  $POST_SCRIPT "$DOMAIN_NAME"
fi
