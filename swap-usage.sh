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
  local size=$1

  if [ -z "$size" ]; then
    size=0
  fi

  if hash bc 2>/dev/null; then
    if [ "$size" -ge 1048576 ]; then
      # size=$(echo $((size/1048576)))gb
      size=$(echo "scale=2;$size/1048576"| bc)gB
    elif [ "$size" -ge 1024 ]; then
      # size=$(echo $((size/1024)))mb
      size=$(echo "scale=2;$size/1024" | bc)mB
    else
      size=$size"kB"
    fi
  else
    size=$size"kB"
  fi

  echo "$size"
}

# print table header
printf "%s" "$COL_RESET"
#printf '=%.0s' {1..64}
printf '=%.0s' {1..50}
printf '\n'
# printf "$COL_RESET%-9s %-21s %-14s %s\n$COL_RESET" "PID" "Name" "Swap used" "Memory used"
printf "$COL_RESET%-9s %-21s %s\n$COL_RESET" "PID" "Name" "Swap used"
# printf '=%.0s' {1..64}
printf '=%.0s' {1..50}
printf '\n'
printf "%s" "$COL_RESET"

MEM_TOTAL=0
SWAP_TOTAL=0
for file in $(find "/proc" -name "status" -type f 2>/dev/null | sort -V); do
  if [ -e "$file" ]; then
    NAME=$(awk '/^Name/{$1=""; print $0} END { print ""}' "$file")
    PID=$(awk '/^Pid/{printf $2} END { print ""}' "$file")
    VMSIZE=$(awk '/^VmSize/{printf $2} END { print ""}' "$file")
    VMSWAP=$(awk '/^VmSwap/{printf $2} END { print ""}' "$file")

    if [ -n "$VMSIZE" ]; then
      export MEM_TOTAL+="$VMSIZE"
    fi

    if [ -n "$VMSWAP" ]; then
      if [ "$VMSWAP" -gt 0 ]; then
        let SWAP_TOTAL+="$VMSWAP"
        printf "$COL_RED%-8s $COL_YELLOW%-22s $COL_GREEN%s\n$COL_RESET" "${PID}" "${NAME}" "$(formatSize "${VMSWAP}")"
        # printf "$COL_RED%-8s $COL_YELLOW%-22s $COL_GREEN%-14s %s\n$COL_RESET" "${PID}" "${NAME}" $(formatSize ${VMSWAP}) $(formatSize ${VMSIZE})
      #else
      #  # print zero-sized entry
      #  printf "$COL_RED%-8s $COL_YELLOW%-22s $COL_GREEN%s\n$COL_RESET" "${PID}" "${NAME}" "0kB" $(formatSize ${VMSIZE})
      fi
    #else
    #  # no swap usage
    #  printf "$COL_RED%-8s $COL_YELLOW%-22s $COL_GREEN%-14s %s\n$COL_RESET" "${PID}" "${NAME}" "0kB" $(formatSize ${VMSIZE})
    fi
  fi
done

# print footer including total usage
printf "%s" "$COL_RESET"
printf '=%.0s' {1..50}
# printf '=%.0s' {1..64}
printf '\n'
# printf "$COL_RESET%-9s %-21s $COL_GREEN%-14s %s\n$COL_RESET" "" "Total:" $(formatSize ${SWAP_TOTAL}) $(formatSize ${MEM_TOTAL})
printf "$COL_RESET%-9s %-21s $COL_GREEN%s\n$COL_RESET" "" "Total:" "$(formatSize "${SWAP_TOTAL}")"
printf '=%.0s' {1..50}
# printf '=%.0s' {1..64}
printf '\n'
printf "%s" "$COL_RESET"

exit 0
