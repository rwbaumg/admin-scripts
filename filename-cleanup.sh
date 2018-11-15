#!/bin/bash

MV_CMD="mv -v"
# MV_CMD="echo mv -v"

# print out commands to clean filenames in the current directory
for i in *' '*; do \
   ${MV_CMD} "$i" `echo $i | sed -e 's/ /_/g' -e 's/(//g' -e 's/)//g' `; \
done

exit 0
