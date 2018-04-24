#!/bin/bash

DEBFILE="$1"

if [[ ! -f "$DEBFILE" ]]; then
  echo >&2 "ERROR: Must supply path to package."
  exit 1
fi

dpkg -c $DEBFILE | awk '{ print $6 }' | sort
exit 0
