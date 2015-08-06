#!/bin/bash
# greps current apache logfiles for mod_security warnings

grep -i modsec /var/log/apache2/*error*log \
| grep -v "Warning" \
| grep -v "(http://www.modsecurity.org/) configured." \
| grep -v "compiled version=" \
| sed "s/$/\\n/"
