#!/bin/bash
# get some info about the current host in a nifty one-liner
# rwb[at]0x19e.net

(printf "%s - %s\n" "$(date)" "$(hostname --fqdn)"; \
 uname -a; echo; \
 uptime; \
 id; \
 who -apb; \
 echo; df -hT; echo; \
 grep "model name" /proc/cpuinfo | uniq -c; \
 grep MemTotal /proc/meminfo | uniq -c; \
 ifconfig | grep 'inet addr'; \
 echo; \
 wget --output-document=/dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip /dev/null 2>&1 | grep --before-context=5 saved; \
 echo; \
 if hash finger 2>/dev/null; then finger root; fi; \
 lsof -i) | uniq
