#!/bin/bash
# Extract URLs from an HTML document, sort and write unique entries in CSV format.
# This script can be used to collate multiple exported browser bookmarks backup files.

# FORMAT="csv"
# FORMAT="trac-links"
# FORMAT="trac-table"
# FORMAT="md-links"

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

function create_trac_links() {
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
                        echo "- [${link// /\%20/} ${desc}]"
                fi
        done
}

if [ -z "$1" ]; then
        usage
        exit 1
fi

if [ -z "${FORMAT+set}" ]; then
	export FORMAT="csv"
fi
if [ -z "${FORMAT}" ]; then
	echo >&2 "ERROR: Output format not specified."
	exit 1
fi

case "$FORMAT" in
	default|csv)
		if ! OUTPUT=$(create_csv "$@"); then
			echo >&2 "ERROR: Failed to create CSV file."
			exit 1
		fi
	;;
	trac|trac-links)
		if ! OUTPUT=$(create_trac_links "$@"); then
			echo >&2 "ERROR: Failed to create Trac links markup."
			exit 1
		fi
	;;
	*)
		echo >&2 "ERROR: Unsupported output format '${FORMAT}'."
		exit 1
	;;
esac

echo "${OUTPUT}" | sort | uniq

exit 0
