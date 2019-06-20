#!/bin/bash
# shows system swap usage
# rwb[at]0x19e[dot]net

# check if awk command exists
hash awk 2>/dev/null || { echo >&2 "You need to install awk. Aborting."; exit 1; }

# Colors
export ESC_SEQ="\x1b["
export COL_RESET=$ESC_SEQ"39;49;00m"
export COL_RED=$ESC_SEQ"31;01m"
export COL_GREEN=$ESC_SEQ"32;01m"
export COL_YELLOW=$ESC_SEQ"33;01m"
export COL_BLUE=$ESC_SEQ"34;01m"
export COL_MAGENTA=$ESC_SEQ"35;01m"
export COL_CYAN=$ESC_SEQ"36;01m"

function formatSize() {
    if [ -z "$1" ]; then
        echo -n "NULL"
        return 1
    fi

    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]] ; then
        echo -n "NaN"
        return 1
    fi

    local value
    value=$1
    # value=$(($1 * 1024))

    if [ "$value" -lt 1000 ]; then
        echo -n "${value} bytes"
        return 0
    fi

    echo -n "$value" |  awk '
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

# print table header
#printf "%s" "$COL_RESET"
#printf '=%.0s' {1..64}
echo -n -e "$COL_RESET"
printf '=%.0s' {1..50}
printf '\n'
# printf "$COL_RESET%-9s %-21s %-14s %s\n$COL_RESET" "PID" "Name" "Swap used" "Memory used"
printf "$COL_RESET%-9s %-21s %s\n$COL_RESET" "PID" "Name" "Swap used"
# printf '=%.0s' {1..64}
printf '=%.0s' {1..50}
echo -n -e "$COL_RESET"
printf '\n'
#printf "%s" "$COL_RESET"

declare -a pid_list=();
function add_pid()
{
  if [ -z "$1" ]; then
    echo >&2 "ERROR: PID cannot be null."
    exit 1
  fi
  if ! echo "${pid_list[@]}" | grep -q -w "$1"; then
    pid="$1"
    pid_list=("${pid_list[@]}" "${pid}")
  fi
}

MEM_TOTAL=0
SWAP_TOTAL=0

function get_table() {
for file in $(find "/proc" -name "status" -type f 2>/dev/null | sort -V); do
  if [ -e "$file" ]; then
    NAME=$(awk '/^Name/{$1=""; print $0} END { print ""}' "$file")
    PID=$(awk '/^Pid/{printf $2} END { print ""}' "$file")
    VMSIZE=$(awk '/^VmSize/{printf $2} END { print ""}' "$file")
    VMSWAP=$(awk '/^VmSwap/{printf $2} END { print ""}' "$file")

    if [ -n "$PID" ]; then

    if ! echo "${pid_list[@]}" | grep -q -w "$PID"; then

    if [ -n "$VMSIZE" ]; then
      (( MEM_TOTAL+=VMSIZE ))
      add_pid "$PID"
    fi

    if [ -n "$VMSWAP" ]; then
      if [ "$VMSWAP" -gt 0 ]; then
        (( SWAP_TOTAL+=VMSWAP ))
        add_pid "$PID"
        printf "$COL_RED%-8s $COL_YELLOW%-22s $COL_GREEN%s\n$COL_RESET" "${PID}" "${NAME}" "$(formatSize $((VMSWAP*1024)))"
      fi
    fi
    fi
    fi
  fi
done
}

get_table #| uniq # | sort -n | uniq

# print footer including total usage
#printf "%s" "$COL_RESET"
echo -n -e "$COL_RESET"
printf '=%.0s' {1..50}
# printf '=%.0s' {1..64}
printf '\n'
printf "$COL_RESET%-9s %-21s $COL_GREEN%s\n$COL_RESET" "" "Total:" "$(formatSize $((SWAP_TOTAL*1024)))"
printf '=%.0s' {1..50}
# printf '=%.0s' {1..64}
printf '\n'
#printf "%s" "$COL_RESET"

exit 0
