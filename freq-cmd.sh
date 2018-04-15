#!/bin/bash
# print a list of the most frequently used commands

# the number of commands to list
COUNT=20

cat ~/.bash_history \
  | awk '{a[$1]++}END{for(i in a){print a[i] " " i}}' \
  | sort -rn \
  | head -n $COUNT

exit 0
