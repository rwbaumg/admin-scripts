#!/bin/bash
# Flattens a text file by removing all leading and trailing
# space characters from each line of text.

file=$1
if [ -z "$file" ]; then
  echo "Usage: $0 <text-file>"
  exit 1
fi

if ! [ ! -s "$file" ] | [ "$(file --mime-type $file | grep -Po 'text/')" == "text/" ]; then
  echo "File is not a valid text file: $file"
  exit 1
fi

# strip leading and trailing space characters from each line
# - to remove blank lines: sed '/^$/d'
# - to remove leading whitespace: sed -e 's/^[ \t]*//'
# - to remove trailing whitespace: sed 's/[ \t]*$//'

cat $file | sed 's/^[ \t]*//;s/[ \t]*$//' > $file.flat

echo "Saved file to: $file.flat"

exit 0
