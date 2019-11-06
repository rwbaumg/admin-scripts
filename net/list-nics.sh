#!/bin/bash
# List Network Interface Device(s) excluding 'lo' and 'vif.*' interfaces

# Set the path to the network device file
DEV_FILE="/proc/net/dev"

# Define a RegEx to filter output NICs
# DEV_FILTER="(lo|vif)"
DEV_FILTER="(lo)"

# Define a RegEx to filter output NICs
DEV_SELECT=""
if [ -n "$1" ]; then
  DEV_SELECT="$1"
fi

if [ ! -e "${DEV_FILE}" ]; then
  echo >&2 "ERROR: File does not exist: ${DEV_FILE}"
  exit 1
fi

if ! NICS=$(tail -n+3 "${DEV_FILE}" \
              | awk -F: '{ print $1 }' \
              | tr -d ' ' \
              | sort -h \
              | uniq \
              | grep -vE "${DEV_FILTER}"); then
  echo >&2 "ERROR: Failed to determine local Network Interface Card(s) (NICs)."
  exit 1
fi

function list_nics() {
  local filter req_state dev_up dev_path
  if [ -e "$1" ] && [ "$1" != "*" ]; then
    filter=1
    req_state="$1"
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
        dev_up=1
        shift
      ;;
      up)
        dev_up=0
        shift
      ;;
      unknown)
        dev_up=-1
        shift
      ;;
      *)
        # unknown state
        echo >&2 "ERROR: Device '${dev}' state '${dev_state}' is not supported."
        dev_up=-2
        exit 1
      ;;
    esac

    if [[ ${filter} -ne 1 ]] || [ ${dev_up} -eq "${req_state}" ]; then
      printf "$COL_RESET%-24s : %s\n" "${dev}" "${dev_state}"
    fi
  done

  return 0
}

if [ -n "${DEV_SELECT}" ]; then
  if ! list_nics "*" | sort -t: -k2 | grep -Ei "${DEV_SELECT}"; then
    exit 1
  fi
else
  if ! list_nics "*" | sort -t: -k2; then
    exit 1
  fi
fi

exit 0
