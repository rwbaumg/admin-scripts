#!/bin/bash
# list open log files

sudo lsof \
    | grep -P "(\.log|/log/)" \
    | awk '{printf("%s\t%s\n",$2,$NF);}' \
    | sort -u

exit 0
