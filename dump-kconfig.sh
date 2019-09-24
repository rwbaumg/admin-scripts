#!/bin/bash
# Dump running kernel configuration

KERNEL_VERSION=$(uname -r)
KCONFIG_PATH="/boot/config-${KERNEL_VERSION}"

if [ ! -e "${KCONFIG_PATH}" ]; then
  echo "ERROR: Kernel configuration '${KCONFIG_PATH}' not found." >&2
  exit 1
fi

cat "${KCONFIG_PATH}"
exit 0
