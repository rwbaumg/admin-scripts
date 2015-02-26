#!/bin/bash
LOGPATTERN="/var/log/syslog*"
grep "iptables dropped:" $LOGPATTERN | awk  -F" " '$22 ~ /^DPT/{printf("%-15s\t%s/%s\n", $13, $22, $20);next}{printf("%-15s\t%s/%s\n", $13, $23, $21)}' | sed s/SRC=// | sed s/PROTO=// | sed s/DPT=// | sort -n | uniq -c | sort -rn | head -n 10
