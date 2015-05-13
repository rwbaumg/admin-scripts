#!/bin/bash
# secure swap erasure

# check if sswap command exists
hash sswap 2>/dev/null || { echo >&2 "You need to install secure-delete. Aborting."; exit 1; }

# find the swap device
SWAP_DEVICE=$(swapon -s | grep /dev | awk '{print $1}')
if [[ -z "$SWAP_DEVICE" ]]; then
  echo "Failed to determine swap device. Does one exist?"
  exit 1
else
  echo "Found swap device: $SWAP_DEVICE"
fi

# turn swap off
swapoff $SWAP_DEVICE

# clear swap
sswap $SWAP_DEVICE

# turn swap back on
swapon $SWAP_DEVICE

echo "Swap erased!"

exit 0
