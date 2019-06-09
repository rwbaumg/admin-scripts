#!/bin/bash
# generates a random password
# uses /dev/random to ensure good random numbers

RNG_DEV="/dev/random"

# Strong passwords should be at least this long
DEFAULT_LENGTH="20"

# Standard charset is alphanumeric with upper and
# lower case w/ some special characters
CHARSET="A-Za-z0-9_"

# Use the below charset for higher entropy
# CHARSET="A-Za-z0-9_\$#!@&%^*~=+,.<>[]/\\\"\'\`"

LENGTH="$1"
re='^[0-9]+$'
if ! [[ $LENGTH =~ $re ]] ; then
  LENGTH=$DEFAULT_LENGTH
fi

PASSWD=$(head $RNG_DEV | tr -dc "$CHARSET" | head -c $LENGTH)

echo "${PASSWD}"

exit 0
