#!/bin/bash
# creates a plot of system boot tasks
# the plot can be used to determine which
# startup tasks are taking the longest time
# to complete

hash systemd-analyze 2>/dev/null || { echo >&2 "This system does not appear to use systemd (the systemd package was not detected). Aborting."; exit 1; }

# determine the directory this script is in and store it in SCRIPT_DIR
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where
  # the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

OUT_FILE="$SCRIPT_DIR/boot.svg"

echo "Generating systemd plot file $OUT_FILE ..."

systemd-analyze plot > $OUT_FILE

echo " done."

exit 0
