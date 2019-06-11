#!/usr/bin/env bash
# Date/time helpers

function displaytime {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && printf '%d days ' $D
  (( $H > 0 )) && printf '%d hours ' $H
  (( $M > 0 )) && printf '%d minutes ' $M
  (( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
  printf '%d seconds\n' $S
}

function countdown(){
   start_date=$(($(date +%s) + $1));
   while [ "$start_date" -ge $(date +%s) ]; do
     echo -ne "$(date -u --date @$(($start_date - $(date +%s))) +%H:%M:%S)\r";
     sleep 0.1
   done
}

function stopwatch(){
  start_date=$(date +%s);
   while true; do
    echo -ne "$(date -u --date @$(($(date +%s) - $start_date)) +%H:%M:%S)\r";
    sleep 0.1
   done
}
