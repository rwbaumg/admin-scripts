#!/bin/bash
# Find and display available EDIDs

DIR_NAME="/sys"
FILENAME="edid"
NO_COLOR="0"

# If the below value is set, edid-decode will not be used.
# NO_DECODE="1"

# check if edid-decode is installed
HAS_EDID_DECODE=0
if hash edid-decode 2>/dev/null; then
  HAS_EDID_DECODE=1
fi

print_cyan()
{
  if [ "${NO_COLOR}" -ne "1" ]; then
  echo -e "\x1b[39;49;00m\x1b[36;01m${1}\x1b[39;49;00m" #> $(tty) 2>&1 < $(tty)
  else
  echo "${1}" #> $(tty) 2>&1 < $(tty)
  fi
}

print_red()
{
  if [ "${NO_COLOR}" -ne "1" ]; then
  echo -e "\x1b[39;49;00m\x1b[31;01m${1}\x1b[39;49;00m" #> $(tty) 2>&1 < $(tty)
  else
  echo "${1}" #> $(tty) 2>&1 < $(tty)
  fi
}

FOUND_EDID=0
EDID_ROKAY=0
while read -r line; do
  if [ ! -s "${line}" ]; then
  if ! raw_edid=$(hexdump -C "${line}"); then
    echo >&2 "WARNING: Failed to read EDID: ${line}";
  fi
  FOUND_EDID=1
  if [ -n "${raw_edid}" ]; then
    print_cyan "${line}";
    echo "${raw_edid}";
    EDID_ROKAY=1;
    if [ "${HAS_EDID_DECODE}" -eq "1" ] && [ -z "${NO_DECODE}" ]; then
      edid-decode -ec "${line}"
    fi
  else
    print_red "WARNING: EDID is empty: ${line}"
  fi
  fi
done < <(find "${DIR_NAME}" -name "${FILENAME}" 2>/dev/null)

if [ "${FOUND_EDID}" -ne "0" ]; then
  if [ "${EDID_ROKAY}" -eq "0" ]; then
    echo >&2 "ERROR: Failed to read any available EDIDs."
    exit 1
  fi
else
  echo >&2 "ERROR: Failed to locate any EDIDs under ${DIR_NAME}."
  exit 1
fi

exit 0
