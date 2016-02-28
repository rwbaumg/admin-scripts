#!/bin/bash
# shows system swap usage
# rwb[at]0x19e[dot]net

SWAP_TOTAL=0

echo "Swap usage"
echo "----------"

for file in /proc/*/status ; do
  NAME=$(awk '/^Name/{$1=""; print $0} END { print ""}' $file)
  PID=$(awk '/^Pid/{printf $2} END { print ""}' $file)
  VMSWAP=$(awk '/^VmSwap/{printf $2} END { print ""}' $file)

  if [ -n "$VMSWAP" ]; then
    if [ $VMSWAP -gt 0 ]; then
      let SWAP_TOTAL+=$VMSWAP
      echo "$NAME: ${VMSWAP}kb"
      # echo "$NAME ($PID): ${VMSWAP}kb"
    fi
  fi
done

echo "----------"
echo "Total: ${SWAP_TOTAL}kb"

exit 0
