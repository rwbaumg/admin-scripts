#!/bin/bash
# shows system swap usage
# rwb[at]0x19e[dot]net

# check if awk command exists
hash awk 2>/dev/null || { echo >&2 "You need to install awk. Aborting."; exit 1; }

# print table header
printf '=%.0s' {1..50}
printf '\n'
printf "%-9s %-21s %s\n" "PID" "Name" "Swap used"
printf '=%.0s' {1..50}
printf '\n'

SWAP_TOTAL=0
for file in /proc/*/status ; do
  NAME=$(awk '/^Name/{$1=""; print $0} END { print ""}' $file)
  PID=$(awk '/^Pid/{printf $2} END { print ""}' $file)
  VMSWAP=$(awk '/^VmSwap/{printf $2} END { print ""}' $file)

  if [ -n "$VMSWAP" ]; then
    if [ $VMSWAP -gt 0 ]; then
      let SWAP_TOTAL+=$VMSWAP
      printf "%-8s %-22s %s\n" "${PID}" "${NAME}" "${VMSWAP}kb"
    fi
  fi
done

# print footer including total usage
printf '=%.0s' {1..50}
printf '\n'
printf "%-9s %-21s %s\n" "" "Total:" "${SWAP_TOTAL}kb"
printf '=%.0s' {1..50}
printf '\n'

exit 0
