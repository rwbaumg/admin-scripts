#!/bin/bash
# List Network Interface Device(s) excluding 'lo' and 'vif.*' interfaces

DEV_FILE="/proc/net/dev"
if [ ! -e "${DEV_FILE}" ]; then
  echo >&2 "ERROR: File does not exist: ${DEV_FILE}"
  exit 1
fi

if ! NICS=$(cat "${DEV_FILE}" \
              | tail -n+3 \
              | awk -F: '{ print $1 }' \
              | tr -d ' ' \
              | sort -h \
              | uniq \
              | grep -vE '(lo|vif)'); then
  echo >&2 "ERROR: Failed to determine local Network Interface Card(s) (NICs)."
  exit 1
fi

echo "${NICS}" | while read -r dev; do
  dev_path="/sys/class/net/${dev}/operstate"
  if [ ! -e "${dev_path}" ]; then
    echo >&2 "ERROR: Device file not found: ${dev_path}"
    exit 1
  fi

  dev_up=0
  dev_state=$(cat "${dev_path}")
  case "${dev_state}" in
    down)
      dev_up=0
      shift
    ;;
    up)
      dev_up=1
      shift
    ;;
    *)
      # unknown state
      echo >&2 "ERROR: Unknown device state '${dev_state}'."
      exit 1
    ;;
  esac

  printf "$COL_RESET%-24s : %s\n" "${dev}" "${dev_state}"
done

exit 0
