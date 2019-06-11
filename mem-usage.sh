#!/bin/bash
# Prints a table of top memory consuming processes

printf "NPROC\t\t\tUSER\tCPU\tMEM\n"

ps --no-headers -eo user:20,pcpu,pmem \
  | awk '{num[$1]++; cpu[$1] += $2; mem[$1] += $3} END{for (user in cpu) printf("%d\t%20s\t%.2f\t%.2f\n", num[user], user, cpu[user], mem[user]) }' \
  | sort -k4nr

exit 0
