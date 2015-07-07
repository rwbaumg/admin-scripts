#!/bin/bash
# TripWire Dump Config

hash tripwire 2>/dev/null || { echo >&2 "You need to install tripwire. Aborting."; exit 1; }

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where 
  # the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

echo "Writing configuration to $DIR ..."
twadmin --print-polfile > "$DIR/twpol.txt"
twadmin --print-cfgfile > "$DIR/twcfg.txt"

echo "Setting permissions on plaintext configuration files ..."
chmod 600 "$DIR/twpol.txt"
chmod 600 "$DIR/twcfg.txt"

echo "Plaintext configuration dumped to $DIR"

exit 0
