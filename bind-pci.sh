#!/bin/bash
# Helper script for managing PCI drivers
# TODO: Needs input checking to validate PCI address

check_root() {
  # check if superuser
  if [[ $EUID -ne 0 ]]; then
     echo "Root is required to perform this operation." >&2
     exit 1
  fi
}

unbind() {
  # Unbind a PCI function from its driver as necessary
  if [ ! -e "/sys/bus/pci/devices/$1" ]; then
    echo "ERROR: Device '$1' does not exist." >&2
    exit 1
  fi
  check_root
  if [ -e "/sys/bus/pci/devices/$1/driver/unbind" ]; then
    echo "Unbinding $1 ..."
    if ! echo -n "$1" > "/sys/bus/pci/devices/$1/driver/unbind"; then
      echo "ERROR: Failed to unbind device." >&2
      exit 1
    fi
  fi
}

bind() {
  if [ ! -e "/sys/bus/pci/devices/$1" ]; then
    echo "ERROR: Device '$1' does not exist." >&2
    exit 1
  fi
  check_root
  echo "Binding $1 to /sys/bus/pci/drivers/$2 ..."
  # Add a new slot to the PCI Backends list
  if ! echo -n "$1" > "/sys/bus/pci/drivers/$2/new_slot"; then
    echo "ERROR: Failed to create new slot." >&2
    exit 1
  fi
  # Now that the backend is watching for the slot, bind to it
  if ! echo -n "$1" > "/sys/bus/pci/drivers/$2/bind"; then
    echo "ERROR: Failed to bind device." >&2
    exit 1
  fi
}

usage()
{
    echo "Usage: $0 (bind|unbind|info) [driver]" >&2
    exit 3
}

test_arg()
{
    # Used to validate user input
    local arg="$1"
    local argv="$2"

    if [ -z "$arg" ]; then
      usage
    fi

    if [ -z "$argv" ]; then
        if echo "$arg" | grep -qE '^-'; then
            usage "Null argument supplied for option $arg"
        fi
    fi

    if echo "$argv" | grep -qE '^-'; then
        usage "Argument for option $arg cannot start with '-'"
    fi
}

case $1 in
  bind)
    test_arg "$2"
    if [ -z "$3" ]; then
      usage
    fi
    pci_dev=$2
    driver=$3
    # re-bind device
    unbind "$pci_dev"
    bind "$pci_dev" "$driver"
    ;;
  unbind)
    test_arg "$2"
    pci_dev=$2
    unbind "$pci_dev"
    ;;
  info)
    test_arg "$2"
    pci_dev=$2
    if ! current_driver=$(lspci -k -s "$pci_dev" | grep "Kernel driver in use:" | head -n1 | awk '{print $5}'); then
      echo "ERROR: Failed to get device information for '$pci_dev'." >&2
      exit 1
    fi
    if [ -n "$current_driver" ]; then
      echo "PCI device $pci_dev is currently bound to $current_driver"
    else
      echo "PCI device $pci_dev is unbound."
    fi
    ;;
  bind|unbind|info)
    # As we don't know which driver was bound before, there is not much we can do here
    ;;
  *)
    usage
    ;;
esac

exit 0
