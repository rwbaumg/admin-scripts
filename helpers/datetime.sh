#!/usr/bin/env bash
# Date/time helpers

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
