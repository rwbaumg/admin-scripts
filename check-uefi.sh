#!/bin/bash

if [ -d /sys/firmware/efi ]; then
  echo "Using UEFI"
else
  echo "Using BIOS"
fi

# [ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
