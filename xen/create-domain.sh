#!/bin/bash
# create a new xen domain
# this script also checks for post-up scripts
# following the format '<domain_name>.sh'
# requires xen-tools package (xl) toolchain
# [0x19e Networks] rwb@0x19e.net

# check if xl command exists
hash xl 2>/dev/null || { echo >&2 "You need to install xen-tools. Aborting."; exit 1; }

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
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

# check if domain is already running
PS_OUT=$(pgrep -f 'xl\screate\s.*\/etc\/xen\/'"$DOMAIN_NAME"'\.cfg')
if [ -n "$PS_OUT" ]; then
  pid=$(echo "$PS_OUT" | awk '{print $1}')
  if ( kill -0 "$pid" > /dev/null 2>&1; ); then
    echo "The domain $DOMAIN_NAME is already running under xl on pid $pid"
    exit 1
  fi
fi

# create the new domain
xl create "$DOMAIN_CONF"

if [ -x "$POST_SCRIPT" ]; then
  echo "Running post-script $POST_SCRIPT ..."
  $POST_SCRIPT "$DOMAIN_NAME"
fi
