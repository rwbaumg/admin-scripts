#!/bin/bash
LOGPATTERN="/var/log/syslog"
grep "iptables dropped:" "$LOGPATTERN"* \
  | awk  -F" " '$22 ~ /^DPT/{printf("%-15s\t%s/%s\n", $13, $22, $20);next}{printf("%-15s\t%s/%s\n", $13, $23, $21)}' \
  | sed s/SRC=// \
  | sed s/PROTO=// \
  | sed s/DPT=// \
  | sort -n \
  | uniq -c \
  | sort -rn \
  | head -n 50

# dmesg | grep -P '^\[\d+\.\d+\]\siptables dropped:\sIN\=([A-Za-z0-9\.]+)\sOUT\=([A-Za-z0-9\.]+)?\sPHYSIN\=([A-Za-z0-9\.]+)?\sMAC\=([0-9A-Fa-f]{2}[:-]){13}([0-9A-Fa-f]{2})\sSRC\=(?:[0-9]{1,3}\.){3}[0-9]{1,3}\sDST\=(?:[0-9]{1,3}\.){3}[0-9]{1,3}\sLEN\=(\d+)\sTOS\=(0[xX][0-9a-fA-F]+)\sPREC\=(0[xX][0-9a-fA-F]+)\sTTL\=(\d+)\sID\=(\d+)\sPROTO\=(TCP|UDP)\sSPT\=(\d+)\sDPT\=(\d+)\sWINDOW\=\d\sRES\=(0[xX][0-9a-fA-F]+)\s(RST\s)?(URGP\=\d)?'
