#!/bin/bash
# Outputs a list of icon names

ICONS_PATH="/usr/share/icons/gnome/32x32/$1"

if [ ! -e "${ICONS_PATH}" ]; then
  echo >&2 "ERROR: The path '${ICONS_PATH}' does not exist."
  exit 1
fi

function getList()
{
  for f in `find "${ICONS_PATH}" -type f`; do
    ico=$(basename "$f")
    echo "${ico%.*}"
  done
}

NAMES=$(getList)
echo "$NAMES" | sort | uniq

exit 0
