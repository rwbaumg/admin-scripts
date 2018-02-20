#!/bin/bash
# rename.sh [pattern] [old] [new] paths...
# 'pattern' should be quoted, and is used to filter files
# 'old' can be a regular expression
# 'paths...' is optional, and allows specifying one or more paths

hash sed 2>/dev/null || { echo >&2 "You need to install sed. Aborting."; exit 1; }

criteria=$1
re_match=$2
replace=$3

shift; shift; shift;
find $* -type f -name "*$criteria*" -print0 \
    | while IFS= read -r -d '' file;
do
    src=$file
    tgt=$(echo $file | sed -e "s/$re_match/$replace/")
    if [ "$src" != "$tgt" ]; then
        mv -v "$src" "$tgt"
    fi
done

exit 0
