#!/bin/bash
netstat -an | awk '{print $5}' | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | grep -v "(`for i in \`ip addr | grep inet |grep eth0 | cut -d/ -f1 | awk '{print $2}'\`;do echo -n "$i|"| sed 's/\./\\\./g;';done`127\.|0\.0\.0)" | sort -n | uniq -c | sort -n
