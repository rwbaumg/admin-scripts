#!/bin/bash
# list open log files

sudo lsof \
    | grep "\.log$" \
    | awk '{printf("%s\t%s\n",$2,$NF);}' \
    | sort -u

exit 0
