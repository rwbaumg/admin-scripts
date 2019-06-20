#!/bin/bash
# print a list of the most frequently used commands

# the number of commands to list
COUNT=20

awk '{a[$1]++}END{for(i in a){print a[i] " " i}}' ~/.bash_history \
  | sort -rn \
  | head -n $COUNT

exit 0
