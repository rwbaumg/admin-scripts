#!/bin/bash
# searches for files/folders with o+w permission bit

find / -xdev \( -perm o+w \) -type f -print0 2>&- | xargs -0 ls -l

exit 0
