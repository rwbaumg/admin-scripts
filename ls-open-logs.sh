#!/bin/bash
# list open log files

sudo lsof \
    | grep -P "(\.log|/log/)" \
    | awk '{ if ($NF == "(deleted)") { printf("%s\t%s %s\n",$2,$(NF-1),$NF); } else if ($NF != "(deleted)") { printf("%s\t%s\n",$2,$NF); } }' \
    | sort -u

exit 0
