#!/bin/bash
# create a script to clean kernel modules
# the current kernel is excluded for posterity

TMP=*
if [[ ! -z "$1" ]]; then
  TMP=$1
fi

PATTERN=$TMP bash -c 'echo "# clean kernel modules matching pattern \"$PATTERN\"";
                      echo "# WARNING: DOUBLE-CHECK COMMANDS BEFORE RUNNING!";
                      for f in `ls -d /lib/modules/$PATTERN | grep -v $(uname -r)`; do
                      echo sudo rm -v -r $f; done'

exit 0
