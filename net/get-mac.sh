#!/usr/bin/env bash
# Determine Mfg. from MAC OUI

ouifile="$(dirname "$0")/../oui.txt"

# Print header
printf "\n  MAC address OUI checker \n\n"

# Error messages
fatal_error() {
        printf "  Usage: perl $0 \n\n";

        printf "  MAC can be submitted as: \n"
        printf "                001122334455 \n"
        printf "                00:11:22:33:44:55 \n"
        printf "                00-11-22-33-44-55 \n"
        printf "        OUI can be submitted as: \n"
        printf "                001122 \n"
        printf "                00:11:22 \n"
        printf "                00-11-22 \n\n"

        printf "  Error: No MAC address or OUI specified or could not recognize it.\n\n";

        exit 1
}

# Check if argument has been given
if [ -z "$1" ]; then
        fatal_error
fi

if [ ! -e "${ouifile}" ]; then
    echo "ERROR: Cannot access OUI file '${ouifile}'." >&2
    exit 1
fi

# Removing seperators from MAC address and uppercase chars
OUI=$(echo "${1}" | awk '{ print toupper($0) }')
OUI=${OUI//[^0-9A-F]/}

# Get OUI from MAC
if OUI=$(echo "$OUI" | grep -Eo '^([0-9A-F]{6})'); then
    printf "  Checking OUI: $OUI \n";
else
    fatal_error
fi

if match=$(grep "(base 16)" "${ouifile}" | grep "${OUI}"); then
    if company=$(echo "${match}" | grep -Po '(?<=\(base\s16\))(?:\s+)[^$]+' | sed -e 's/^[\s\t\r\n\b]*//' -e 's/[\s\t\r\n\b]*$//'); then
        printf "  Found OUI: $OUI - $company \n\n";
        exit 0
    fi
fi

# Show if OUI was not found
printf "  Could not find OUI: $OUI \n\n";

exit 1
