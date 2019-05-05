#!/bin/bash
# print an overview of current system load

hash iostat 2>/dev/null || { echo >&2 "You need to install sysstat. Aborting."; exit 1; }

iostat -m

free -m | awk 'NR==2{printf "Memory Usage:\t%s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }'
df -h | awk '$NF=="/"{printf "Disk Usage:\t%d/%dGB (%s)\n", $3,$2,$5}'
top -bn1 | grep load | awk '{printf "CPU Load:\t%.2f\n", $(NF-2)}'

echo -e "\nProcess memory usage:"
ps axo rss,comm,pid | awk '{ proc_list[$2]++; proc_list[$2 "," 1] += $1; } END { for (proc in proc_list) { printf("%d\t%s\n", proc_list[proc "," 1],proc); }}' | sort -n | tail -n 10
# ps -eo user,pcpu,pmem | tail -n +2 | awk '{num[$1]++; cpu[$1] += $2; mem[$1] += $3} END{printf("NPROC\t\tUSER\tCPU\tMEM\n"); for (user in cpu) printf("%d\t%12s\t%.2f\t%.2f\n",num[user], user, cpu[user], mem[user]) }'
