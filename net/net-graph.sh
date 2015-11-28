#!/bin/bash
# create ascii graph of active tcp network connections
# rwb[at]0x19e[dot]net

netstat -ant \
| grep ESTABLISHED \
| awk '{print $5}' \
| awk -F: '{print $1}' \
| sort \
| uniq -c \
| awk '{ printf("%s\t%s\t",$2,$1) ; for (i = 0; i < $1; i++) {printf("*")}; print "" }'
