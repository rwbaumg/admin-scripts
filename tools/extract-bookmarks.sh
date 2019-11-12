#!/bin/bash
# Extract URLs from an HTML document, sort and write unique entries in CSV format.
# This script can be used to collate multiple exported browser bookmarks backup files.

function usage() {
        echo >&2 "Usage: $0 <bookmarks_html_file>..."
}

function create_csv() {
        if [ -z "$1" ]; then
                usage
                exit 1
        fi
        for f in "$@"; do
                if [ ! -e "$f" ]; then
                        echo >&2 "ERROR: Failed to locate HTML file(s): $*"
                        exit 1
                fi
        done

        cat "$@" | while read -r line; do
                link=$(echo "${line}" | grep -Pio '(?<=HREF\=\")[^\"]+(?=\")')
                desc=$(echo "${line}" | grep -Pio '(?<=\"\>)[^\"]+(?=\<\/A\>)')
                if [ ! -z "${link}" ]; then
                        echo "\"${link}\",\"${desc}\""
                fi
        done
}

if [ -z "$1" ]; then
        usage
        exit 1
fi

if ! CSV=$(create_csv "$@"); then
        echo >&2 "ERROR: Failed to create CSV file."
        exit 1
fi

echo "${CSV}" | sort | uniq

exit 0
