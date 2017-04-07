#!/bin/bash
# Helper script for managing PCI drivers
# TODO: Needs input checking to validate PCI address

unbind() {
  # Unbind a PCI function from its driver as necessary
  if [ -e /sys/bus/pci/devices/$1/driver/unbind ]; then
    echo Unbinding $1 ...
    echo -n $1 > /sys/bus/pci/devices/$1/driver/unbind
  fi
}

bind() {
  echo Binding $1 to /sys/bus/pci/drivers/$2 ...
  # Add a new slot to the PCI Backends list
  echo -n $1 > /sys/bus/pci/drivers/$2/new_slot
  # Now that the backend is watching for the slot, bind to it
  echo -n $1 > /sys/bus/pci/drivers/$2/bind
}

case $1 in
  bind)
    pci_dev=$2
    driver=$3

    unbind $pci_dev
    bind $pci_dev $driver
    ;;

  unbind)
    pci_dev=$2

    unbind $pci_dev
    ;;

  info)
    pci_dev=$2
    current_driver=$(lspci -k -s $pci_dev | grep "Kernel driver in use:" | head -n1 | awk '{print $5}')

    echo "PCI device $pci_dev is currently bound to $current_driver"
    ;;

  bind|unbind|info)
    # As we don't know which driver was bound before, there is not much we can do here
    ;;

  *)
    echo "Usage: $0 (bind|unbind|info)" >&2
    exit 3
    ;;

esac
