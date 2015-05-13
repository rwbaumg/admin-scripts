#!/bin/bash
# secure swap erasure

# check if sswap command exists
hash sswap 2>/dev/null || { echo >&2 "You need to install secure-delete. Aborting."; exit 1; }

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# find the swap device
SWAP_DEVICE=$(swapon -s | grep /dev | awk '{print $1}')
if [[ -z "$SWAP_DEVICE" ]]; then
  echo "Failed to determine swap device. Does one exist?"
  exit 1
else
  echo "Found swap device: $SWAP_DEVICE"
fi

# turn swap off
swapoff -v $SWAP_DEVICE

# clear swap
sswap -v $SWAP_DEVICE

# turn swap back on
swapon -v $SWAP_DEVICE

exit 0
