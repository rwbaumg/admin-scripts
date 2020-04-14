#!/bin/bash
# get some info about the current host in a nifty one-liner
# rwb[at]0x19e.net

#SPEEDTEST_URL="http://speedtest.tele2.net/10MB.zip"
#SPEEDTEST_URL="http://speedtest.wdc01.softlayer.com/downloads/test10.zip"
SPEEDTEST_URL="http://chicago02.speedtest.windstream.net:8080/speedtest/random2500x2500.jpg"

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
 wget --output-document=/dev/null "${SPEEDTEST_URL}" /dev/null 2>&1 | grep --before-context=5 saved; \
 echo; \
 if hash finger 2>/dev/null; then finger root; fi; \
 lsof -i) | uniq
