#!/bin/bash
# Scan the desktop for a QR code and decode if found
# Uses zbarimg, for example:
#  zbarimg -q --raw "${temp_file}"

hash gnome-screenshot 2>/dev/null || { echo >&2 "You need to install gnome-screenshot. Aborting."; exit 1; }
hash zbarimg 2>/dev/null || { echo >&2 "You need to install zbar-tools. Aborting."; exit 1; }

function countdown() {
    start_date=$(($(date +%s) + $1));
    while [ "$start_date" -ge "$(date +%s)" ]; do
        seconds=$(date -u --date @$((start_date - $(date +%s))) +%s)
        if [ "$seconds" -eq 0 ]; then
            echo -ne "Taking screenshot ...........\r";
            break;
        else
            echo -ne "Screenshot in $seconds second(s) ...\r";
        fi
        sleep 0.1
    done
}

if ! temp_file=$(mktemp -t screenshot.XXXXXXXXXX.png); then
  echo >&2 "ERROR: Failed to create temporary file for screenshot."
  exit 1
fi

countdown 3

if ! gnome-screenshot -f "${temp_file}"; then
  echo >&2 "ERROR: Failed to take desktop screenshot."
  exit 1
fi

echo -ne "Scanning for barcodes .......\r";

err=0
if ! results=$(zbarimg -q "${temp_file}"); then
  err=1
fi

if [ -e "${temp_file}" ]; then
  rm -f "${temp_file}"
fi

# HACK: Clear the entire line.
echo -ne "\r                             \r"

if [ "${err}" -ne 0 ]; then
  echo >&2 "No barcodes detected."
  exit 1
fi

echo "${results}"
exit 0
