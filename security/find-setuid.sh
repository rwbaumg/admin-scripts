#!/bin/bash
# find all setuid binaries

find / -xdev \( -perm -4000 \) -type f -print0 2>&- | xargs -0 ls -l
