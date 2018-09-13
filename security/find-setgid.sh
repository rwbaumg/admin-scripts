#!/bin/bash
# find all setgid binaries

find / -xdev \( -perm -2000 \) -type f -print0 2>&- | xargs -0 ls -l

exit 0
