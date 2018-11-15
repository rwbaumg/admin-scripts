#!/bin/bash

DRY_RUN="true"

# print out commands to clean filenames in the current directory
for i in *; do
  if `echo $i | grep -Po '\s'`; then
    if [ "$DRY_RUN" == "false" ]; then
      mv -v "$i" `echo $i | sed -e 's/ /_/g' -e 's/(//g' -e 's/)//g' `;
    else
      echo mv -v \"$i\" `echo $i | sed -e 's/ /_/g' -e 's/(//g' -e 's/)//g' `;
    fi
  fi
done

exit 0
