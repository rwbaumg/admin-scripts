#!/bin/bash

ps --no-headers -eo user:20,pcpu,pmem | sort -k1,3n | awk '{num[$1]++; cpu[$1] += $2; mem[$1] += $3} END{printf("NPROC\t\t\tUSER\tCPU\tMEM\n"); for (user in cpu) printf("%d\t%20s\t%.2f\t%.2f\n", num[user], user, cpu[user], mem[user]) }'

#for pid in $(ps --no-headers -ef | awk '{print $2}'); do
#    if [ -e /proc/$pid/smaps ]; then
#      size=$(cat /proc/$pid/smaps 2>/dev/null | grep -m 1 -e ^Size: | awk '{print $2}')
#      if [ -n "${size}" ]; then
#        echo "* Mem usage for PID $pid"
#        echo "-- Size: "$size
#        echo "-- Rss:"
#        cat /proc/$pid/smaps | grep -m 1 -e ^Rss: | awk '{print $2}'
#        echo "-- Pss:"
#        cat /proc/$pid/smaps | grep -m 1 -e ^Pss: | awk '{print $2}'
#        echo "Shared Clean"
#        cat /proc/$pid/smaps | grep -m 1 -e '^Shared_Clean:' | awk '{print $2}'
#        echo "Shared Dirty"
#        cat /proc/$pid/smaps | grep -m 1 -e '^Shared Dirty:' | awk '{print $2}'
#      fi
#    fi
#done
