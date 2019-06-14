#!/bin/bash

# check if curl command exists
hash fortune 2>/dev/null || { echo >&2 "You need to install fortune. Aborting."; exit 1; }
hash cowsay 2>/dev/null || { echo >&2 "You need to install cowsay. Aborting."; exit 1; }

if [ -z "$COWPATH" ]; then
  COWPATH='/usr/share/cowsay/cows/'
fi

cow_file_length=$(find "$COWPATH" -type f | wc -l)

# initialize the random seed with the process id of this script
RANDOM=$$
let "random_line = $RANDOM % $cow_file_length + 1"
cow=$(find "$COWPATH" -type f | head -n "$random_line" | tail -n 1)

fortune | cowsay -n -f "$cow"

exit 0
