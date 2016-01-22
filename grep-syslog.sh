#!/bin/bash
# helpful grep command for parsing syslog

grep -rP "([Ff]ail|[Ee]rror|[Ww]arn)" /var/log/syslog \
  | sed -E "s/\s([A-Za-z0-9]+)\[[0-9]{0,6}\]\:\s/ \1 /g" \
  | cut -d " " -f 4- | sort | uniq \
  | grep -v postfix | grep -v named
