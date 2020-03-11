#!/bin/bash
# List the last modified files in the current directory

find . -type f -exec stat --format '%Y :%y %n' "{}" \; \
  | sort -nr | cut -d: -f2- | head

exit 0
