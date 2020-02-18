#!/bin/bash
# Runs apt-get dist-upgrade so you don't develop carpel-tunnel
# from upgrading your system all the time like you should.

# Note: All arguments are passed to apt-get

hash apt 2>/dev/null || { echo >&2 "You need to install apt. Aborting."; exit 1; }

BASE_COMMAND="sudo apt-get $*"

if ! ${BASE_COMMAND} update; then
  echo >&2 "ERROR: System update failed."
  exit 1
fi
if ! ${BASE_COMMAND} dist-upgrade; then
  echo >&2 "ERROR: System upgrade failed."
  exit 1
fi
if ! ${BASE_COMMAND} autoremove; then
  echo >&2 "ERROR: Package autoremoval failed."
  exit 1
fi

exit 0
