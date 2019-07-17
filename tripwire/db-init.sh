#!/bin/bash
# First-time Tripwire initialization script
# Decrypt policy config:  twadmin --print-polfile > /etc/tripwire/twpol.txt
# Create policy file:     twadmin -m P /etc/tripwire/twpol.txt
# Init. database:         tripwire --init

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
if [ ! -e "/etc/tripwire/twcfg.txt" ]; then
  echo >&2 "ERROR: Missing unencrypted configuration file '/etc/tripwire/twcfg.txt'."
  exit 1
fi
if [ ! -e "/etc/tripwire/twpol.txt" ]; then
  echo >&2 "ERROR: Missing unencrypted configuration file '/etc/tripwire/twpol.txt'."
  exit 1
fi

if [ ! -e "/etc/tripwire/$HOSTNAME-local.key" ]; then
if ! sudo twadmin --generate-keys --local-keyfile "/etc/tripwire/$HOSTNAME-local.key"; then
  echo >&2 "ERROR: Failed to generate local key."
  exit 1
fi
if [ ! -e "/etc/tripwire/$HOSTNAME-local.key" ]; then
  echo >&2 "ERROR: Missing local key file '/etc/tripwire/$HOSTNAME-local.key'."
  exit 1
fi
fi

err=0
pushd /etc/tripwire
if ! sudo twadmin --create-cfgfile --cfgfile tw.cfg --site-keyfile site.key twcfg.txt; then
  echo >&2 "ERROR: Failed to generate configuration file 'twcfg.txt'."
  err=1
fi
if ! sudo twadmin --create-polfile --polfile tw.pol --site-keyfile site.key twpol.txt; then
  echo >&2 "ERROR: Failed to generate configuration file 'twpol.txt'."
  err=1
fi
if ! sudo chmod -v 0600 tw.cfg tw.pol; then
  echo >&2 "ERROR: Failed to configure permissions for Tripwire configuration files."
  err=1
fi
popd
if [ "$err" -ne 0 ]; then
  exit 1
fi

if [ ! -e "/etc/tripwire/tw.cfg" ]; then
  echo >&2 "ERROR: Missing required file: /etc/tripwire/tw.cfg"
  exit 1
fi
if [ ! -e "/etc/tripwire/tw.pol" ]; then
  echo >&2 "ERROR: Missing required file: /etc/tripwire/tw.pol"
  exit 1
fi

err=0
pushd /etc/tripwire
if ! sudo tripwire --init \
                   --cfgfile "/etc/tripwire/tw.cfg" \
                   --polfile "/etc/tripwire/tw.pol" \
                   --site-keyfile "/etc/tripwire/site.key" \
                   --local-keyfile "/etc/tripwire/$HOSTNAME-local.key"; then
  err=1
  echo >&2 "ERROR: Failed to initialize database."
fi
popd
if [ "$err" -ne 0 ]; then
  exit 1
fi

# TODO: Delete un-encrypted configuration files after initialization.
# sudo rm /etc/tripwire/twcfg.txt /etc/tripwire/twpol.txt

echo "Tripwire database initialized; running interactive check..."
if ! sudo tripwire --check --interactive; then
  echo >&2 "ERROR: Interactive check returned an error; Tripwire might not be configured correctly."
  exit 1
fi

echo "NOTE: Remember to delete un-encrypted configuration files after testing:"
echo "      `sudo rm /etc/tripwire/twcfg.txt /etc/tripwire/twpol.txt`"
echo ""
echo "Initialization process completed."

exit 0
