#!/bin/bash
# print usb device info

sudo lsusb -v 2>/dev/null | \
  grep --color=never '^Bus\|iSerial\|idVendor\|idProduct\|bcdDevice\|bcdUSB'

exit 0
