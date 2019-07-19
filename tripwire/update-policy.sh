#!/bin/bash
# Update tw.pol from twpol.txt
# To get the decoded file:
#  sudo sh -c 'twadmin --print-polfile > /etc/tripwire/twpol.txt'

hash sudo 2>/dev/null || { echo >&2 "You need to install sudo. Aborting."; exit 1; }
hash tripwire 2>/dev/null || { echo >&2 "You need to install tripwire. Aborting."; exit 1; }

if [ ! -e "/etc/tripwire" ]; then
  echo >&2 "ERROR: Tripwire configuration directory '/etc/tripwire' does not exist."
  exit 1
fi

if [ ! -e "/etc/tripwire/site.key" ]; then
  echo >&2 "ERROR: Missing site key '/etc/tripwire/site.key' (required)."
  exit 1
fi
if [ ! -e "/etc/tripwire/$HOSTNAME-local.key" ]; then
  echo >&2 "ERROR: Missing local key file '/etc/tripwire/$HOSTNAME-local.key'."
  exit 1
fi

if [ ! -e "/etc/tripwire/twpol.txt" ]; then
  echo >&2 "ERROR: Missing unencrypted configuration file '/etc/tripwire/twpol.txt'."
  exit 1
fi

# Re-generate policy file
if ! sudo twadmin --create-polfile "/etc/tripwire/twpol.txt"; then
  echo "ERROR: Failed to create new encrypted policy file." >&2
  exit 1
fi

if ! sudo tripwire --init; then
  echo "ERROR: Database initialization failed." >&2
  exit 1
fi

exit 0
