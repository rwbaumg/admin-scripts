#!/bin/bash
# TripWire Dump Config

hash tripwire 2>/dev/null || { echo >&2 "You need to install tripwire. Aborting."; exit 1; }

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

SOURCE="${BASH_SOURCE[0]}"
# resolve $SOURCE until the file is no longer a symlink
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve
  # it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

DIR="/etc/tripwire"

if [ ! -e "$DIR/tw.cfg" ]; then
  echo >&2 "ERROR: Configuration file '$DIR/tw.cfg' does not exist."
  exit 1
fi
if [ ! -e "$DIR/tw.pol" ]; then
  echo >&2 "ERROR: Policy configuration '$DIR/tw.pol' does not exist."
  exit 1
fi

echo "Writing policy configuration to $DIR/twpol.txt ..."
if ! twadmin --print-polfile > "$DIR/twpol.txt"; then
  echo >&2 "ERROR: Failed to write policy configuration."
fi

echo "Writing Tripwire configuration to $DIR/twcfg.txt ..."
if ! twadmin --print-cfgfile > "$DIR/twcfg.txt"; then
  echo >&2 "ERROR: Failed to write Tripwire configuration."
fi

echo "Setting permissions on plaintext configuration files ..."
chmod 600 -v "$DIR/twpol.txt"
chmod 600 -v "$DIR/twcfg.txt"

echo "Plaintext configuration files dumped to $DIR"

exit 0
