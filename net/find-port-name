#!/bin/bash
#./update-port-list
grep -i $1 service-names-port-numbers.csv \
     |  awk  -F"," '$5 ~ /^[\[John_Fake\]]/{printf("%-20s %-60s %s/%s\n", $1, substr($4, 1, 55), $2, $3)}'
