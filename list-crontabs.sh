#!/bin/bash
# prints all crontabs

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

for user in $(cut -f1 -d: /etc/passwd); do
  OUT=$( crontab -u $user -l 2>/dev/null )
  if [[ $OUT ]]; then
    echo "crontab for $user"
    printf '%.0s-' {1..20}; echo
    echo "$OUT" | grep -v '^#' | grep -v '^$'
    printf '%.0s-' {1..20}; echo
  fi
done
