#!/bin/bash
# runs a command in the specified schroot
# rwb [ rwb[at]0x19e.net ]

if [[ -z "$1" ]]; then
  echo "Usage: $0 <schroot> [COMMAND]"
  exit 1
fi

# The full path to the schroot binary
SCHROOT_BIN="/usr/bin/schroot"

# The name of the schroot to jail the daemon in
SCHROOT_NAME="$1"

# Get the command to run
CMD_ARGS="${*:2}"

echo -e "schroot \t : $SCHROOT_NAME"
echo -e "command \t : $CMD_ARGS"

# check to make sure the specified schroot actually exists
CHROOT_EXISTS=""
for ch in `$SCHROOT_BIN -l -a|grep "chroot"|awk -F: '{print $2}'`; do
  if [[ $ch == "$SCHROOT_NAME"* ]]; then
    CHROOT_EXISTS="y"
  fi
done
if [[ -z "$CHROOT_EXISTS" ]]; then
  echo "ERROR: The specified chroot, '$SCHROOT_NAME', does not exist."
  exit 1
fi

# Get the schroot session (or create a new one)
SESSION=""
for sn in `$SCHROOT_BIN -l -a|grep "session:"|awk -F: '{print $2}'`; do
  if [[ $sn == "$SCHROOT_NAME"* ]]; then
    SESSION=$sn
  fi
done
if [[ -z "$SESSION" ]]; then
  echo "Creating new schroot session for '$SCHROOT_NAME' ..."
  SESSION=$(schroot --begin-session -c $SCHROOT_NAME)
fi
echo "Using schroot session '$SESSION' ..."

echo "Running command '$CMD_ARGS' ..."
$SCHROOT_BIN --directory / --run-session -c "$SESSION" $CMD_ARGS
