#!/bin/bash
# resets a USB device

# the USB driver to use
USB_DRIVER="xhci_hcd"

if [[ -z "$1" ]]; then
  echo "Usage: $0 <device>" >&2
  exit 1
fi

# check if superuser
if [[ $EUID -ne 0 ]]; then
  echo >&2 "This script must be run as root."
  exit 1
fi

USB_DEVICE="$1"

if [ ! -e "/sys/bus/pci/drivers/$USB_DRIVER/$USB_DEVICE" ]; then
  echo "The specified USB device could not be found." >&2
  exit 1
fi

echo "Resetting USB device /sys/bus/pci/drivers/$USB_DRIVER/$USB_DEVICE ..."

echo -n "$USB_DEVICE" | tee "/sys/bus/pci/drivers/$USB_DRIVER/unbind"
echo -n "$USB_DEVICE" | tee "/sys/bus/pci/drivers/$USB_DRIVER/bind"

exit 0
