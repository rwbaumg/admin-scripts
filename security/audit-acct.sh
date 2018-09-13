#!/bin/bash

hash ac 2>/dev/null || { echo >&2 "You need to install acct. Aborting."; exit 1; }

echo "USERS' CONNECT TIMES"
echo ""

ac -d -p

echo ""
echo "COMMANDS BY USER"
echo ""

users=$(cat /etc/passwd | awk -F ':' '{print $1}' | sort)

for user in $users ; do
  comm=$(lastcomm --user $user | awk '{print $1}' | sort | uniq -c | sort -nr)
  if [ "$comm" ] ; then
    echo "$user:"
    echo "$comm"
  fi
done

echo ""
echo "COMMANDS BY FREQUENCY OF EXECUTION"
echo ""

sa | awk '{print $1, $6}' | sort -n | head -n -1 | sort -nr

exit 0
