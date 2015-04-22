#!/bin/bash
# prints all crontabs

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

printf "$COL_RED%.0s-$COL_RESET" {1..20}; echo
for user in $(cut -f1 -d: /etc/passwd); do
  OUT=$( crontab -u $user -l 2>/dev/null )
  if [[ $OUT ]]; then
    echo -e  "$COL_GREEN crontab for $user $COL_RESET"
    printf "$COL_RED%.0s-$COL_RESET" {1..20}; echo
    echo "   minute (0-59),"
    echo "   | hour (0-23),"
    echo "   | | day of the month (1-31),"
    echo "   | | | month of the year (1-12),"
    echo "   | | | | day of the week (0-6 with 0=Sunday)."
    echo "   | | | | | command(s)"
    echo "   | | | | | |"
    echo "$OUT" | grep -v '^#' | grep -v '^$'
    printf "$COL_RED%.0s-$COL_RESET" {1..20}; echo
  fi
done

echo -e "$COL_YELLOW Finished listing crontabs$COL_RESET"
printf "$COL_RED%.0s-$COL_RESET" {1..20}; echo
