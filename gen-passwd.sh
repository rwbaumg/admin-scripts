#!/bin/bash
# generates a random password

DEFAULT_LENGTH="20"
CHARSET="A-Za-z0-9_"
#CHARSET="A-Za-z0-9_\$#!@&"

LENGTH="$1"
re='^[0-9]+$'
if ! [[ $LENGTH =~ $re ]] ; then
  LENGTH=$DEFAULT_LENGTH
fi

tr -dc "$CHARSET" < /dev/urandom | head -c $LENGTH | xargs
