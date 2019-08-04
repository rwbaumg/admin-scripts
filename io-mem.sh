#!/bin/bash
# Display IO memory mappings

if ! IOMEM_RAW=$(sudo cat /proc/iomem); then
  echo >&2 "ERROR: Failed to read /proc/iomem"
  exit 1
fi

echo "${IOMEM_RAW}" | while IFS= read -r line; do
  pci_addr=$(echo -n "${line}" | grep -Po '(?<=\s\:\s)[0-9]{4}\:[0-9]{2}\:[0-9]{2}\.[0-9]$')
  # pre_tabs=$(echo -n "${line}" | grep -Po '^\s+')
  if [ -n "${pci_addr}" ]; then
    pci_info=$(sudo lspci -v -k -s "${pci_addr}")
    pci_desc=$(echo -n "${pci_info}" | head -n 1)
    # dev_drvr=$(echo -n "${pci_info}" | grep -Po '(?<=Kernel\sdriver\sin\suse\:\s).*$')
    # krnl_drv=$(echo -n "${pci_info}" | grep -Po '(?<=Kernel\smodules\:\s).*$')
    echo "${line} (${pci_desc})"
  else
    echo "${line}"
  fi
done

exit 0
