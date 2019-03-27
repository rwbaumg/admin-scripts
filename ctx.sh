#!/bin/bash
# Script to examine CPU context switching

#if [[ $# -eq 0 ]]
#then
#   echo "Usage:"
#   echo "$0 <core>"
#   exit 1
#fi

#if [[ -z $2 ]]
#then
#   watch -d -n .2 $0 $1 nw
#fi

if [[ ! -z "$1" ]]; then
# filter based on core number
ps -Leo lastcpu:1,tid,comm \
  | grep "^$1 " \
  | awk '{printf $3": ";system("cut -d\" \" -f3 /proc/"$2"/task/"$2"/schedstat 2>/dev/null")}' \
  | sort -k 2nr \
  | column -t \
  | head -n 60
else
# look at all cpu cores
ps -Leo lastcpu:1,tid,comm \
  | awk '{printf $3": ";system("cut -d\" \" -f3 /proc/"$2"/task/"$2"/schedstat 2>/dev/null")}' \
  | sort -k 2nr \
  | column -t \
  | head -n 60
fi

exit 0
