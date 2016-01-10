#!/bin/bash
#
# -=[ 0x19e Networks ]=-
#
# greps system logs for attached disks
#

GREP_LOGS="/var/log/kern.log /var/log/syslog /var/log/dmesg"
GREP_REGEX="Attached (SCSI|scsi)"

cat $GREP_LOGS \
    | grep -P "$GREP_REGEX" | cut -d ' ' -f 13-30 \
    | sort | uniq | sed -e '/^[[:space:]]*$/d'
