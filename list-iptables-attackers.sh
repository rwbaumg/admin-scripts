#!/bin/bash
grep "iptables dropped:" /var/log/syslog | awk  -F" " '$22 ~ /^DPT/{printf("%s \t %s/%s \n", $13, $22, $20);next}{printf("%s \t %s/%s \n", $13, $23, $21)}' | sed s/SRC=// | sed s/PROTO=// | sed s/DPT=// | sort -n | uniq -c | sort -rn | head -n 10
# grep "iptables dropped:" /var/log/syslog* | awk  -F" " '$22 ~ /^DPT/{printf("%s \t %s/%s \n", $13, $22, $20);next}{printf("%s \t %s/%s \n", $13, $23, $21)}' | sed s/SRC=// | sed s/PROTO=// | sed s/DPT=// | sort -n | uniq -c | sort -rn | head -n 10
