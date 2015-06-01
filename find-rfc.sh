#!/bin/bash
# allows searching for an RFC

# check if doc-rfc is installed
stat /usr/share/doc/RFC/rfc-index.txt.gz &> /dev/null || { echo >&2 "You need to install doc-rfc. Aborting."; exit 1; }

if [[ -z "$1" ]]; then
  echo "Usage: $0 <keyword>"
  exit 1
fi

# grep the index file for the specified term
zgrep -i $1 /usr/share/doc/RFC/rfc-index.txt.gz || echo "No subject found for $1"
