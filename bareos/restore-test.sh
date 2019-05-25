#!/bin/bash
#
# A Script for Bacula Restore Test
#
# It selects, randomly x (FILES_PER_JOB) to restore from every Bacula Configured Client into a fixed Restore Client.
#
# Author: Robert W. Baumgartner <rwb@0x19e.net>
# Original script by Heitor Faria - http://www.bacula.com.br | http://bacula.us
#
RESTORE_CLIENT=bareos-fd
FILES_PER_JOB=10

hash bconsole 2>/dev/null || { echo >&2 "You need to install bareos-bconsole. Aborting."; exit 1; }
hash grep 2>/dev/null || { echo >&2 "You need to install grep. Aborting."; exit 1; }
hash sed 2>/dev/null || { echo >&2 "You need to install sed. Aborting."; exit 1; }

for CLIENT in $(echo "llist clients" | bconsole | grep -w '[Nn]ame:' | sed 's/[Nn]ame://g' | sed 's/ //g'); do
  JOBID=$(echo "list jobs client=$CLIENT" | bconsole | grep "| T" | tail -n 1 | cut -f 2 -d "|" | sed 's/[ ,]//g')
  echo "list files jobid=$JOBID" | bconsole |head -n -7 | tail -n +10 |cut -d "|" -f 2 | sed 's/^ //g' | sort -R | head -n $FILES_PER_JOB | sed 's/[ \t]\+$//g' > /tmp/list-"$CLIENT"
  echo "restore jobid=$JOBID client=$CLIENT restoreclient=$RESTORE_CLIENT restorejob=RestoreFiles file=</tmp/list where=/tmp/$CLIENT select done yes" | bconsole
done

exit 0
