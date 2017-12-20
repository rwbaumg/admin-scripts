#!/bin/bash
# creates a plot of systemd targets

hash systemd-analyze 2>/dev/null || { echo >&2 "This system does not appear to use systemd (the systemd package was not detected). Aborting."; exit 1; }
hash dot 2>/dev/null || { echo >&2 "You need to install graphviz. Aborting."; exit 1; }

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

OUT_FILE="$SCRIPT_DIR/targets.svg"

echo "Generating systemd targets plot file $OUT_FILE ..."

systemd-analyze dot --to-pattern='*.target' --from-pattern='*.target' | dot -Tsvg > $OUT_FILE

echo " done."

exit 0
