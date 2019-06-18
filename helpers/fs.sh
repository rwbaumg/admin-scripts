#!/usr/bin/env bash
# Date/time helpers

function formatSizeBc() {
    local size="$1"

    if [ -z "$size" ]; then
        size=0
    fi

    local scale=2
    if hash bc 2>/dev/null; then
        if [ "$size" -ge 1099511627776 ]; then
            size=$(echo "scale=$scale;$size/1099511627776"| bc)" TB"
        elif [ "$size" -ge 1073741824 ]; then
            size=$(echo "scale=$scale;$size/1073741824"| bc)" GB"
        elif [ "$size" -ge 1048576 ]; then
            size=$(echo "scale=$scale;$size/1048576" | bc)" MB"
        elif [ "$size" -ge 1024 ]; then
            size=$(echo "scale=$scale;$size/1024" | bc)" KB"
        else
            size=$size" B"
        fi
    else
        size=$size" B"
    fi

    echo "$size"
    return 0
}

function getSizeString() {
    if [ -z "$1" ]; then
        echo "NULL"
        return 1
    fi

    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]] ; then
        echo "NaN"
        return 1
    fi

    if [ "$1" -lt 1000 ]; then
        echo "${1} bytes"
        return 0
    fi

    echo "$1" |  awk '
        function human(x) {
            if (x<1000) {return x} else {x/=1024}
            s="kMGTEPZY";
            while (x>=1000 && length(s)>1)
                {x/=1024; s=substr(s,2)}
            return sprintf("%.2f", x) " " substr(s,1,1) "B"
            # return int(x+0.5) substr(s,1,1)
        }
        {sub(/^[0-9]+/, human($1)); print}'

    return 0
}
