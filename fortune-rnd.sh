#!/bin/bash

GAMES_DIR=/usr/games

# check if curl command exists
hash fortune 2>/dev/null || { echo >&2 "You need to install fortune. Aborting."; exit 1; }
hash cowsay 2>/dev/null || { echo >&2 "You need to install cowsay. Aborting."; exit 1; }

if [ !$COWPATH ]
then
  COWPATH='/usr/share/cowsay/cows/'
fi

cow_file_length=`ls -1 $COWPATH | wc -l`

RANDOM=$$ # initialized the random seed with the process id of this script
let "random_line = $RANDOM % $cow_file_length + 1"
cow=`ls -1 $COWPATH | head -n $random_line | tail -n 1`

$GAMES_DIR/fortune | $GAMES_DIR/cowsay -n -f $cow

