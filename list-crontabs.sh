#!/bin/bash
# prints all crontabs
# note that crontabs are stored in /var/spool/cron/crontabs
# this just enumerates everything using the crontab command

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# Colors
export ESC_SEQ="\x1b["
export COL_RESET=$ESC_SEQ"39;49;00m"
export COL_RED=$ESC_SEQ"31;01m"
export COL_GREEN=$ESC_SEQ"32;01m"
export COL_YELLOW=$ESC_SEQ"33;01m"
export COL_BLUE=$ESC_SEQ"34;01m"
export COL_MAGENTA=$ESC_SEQ"35;01m"
export COL_CYAN=$ESC_SEQ"36;01m"

printf "$COL_RED%.0s-$COL_RESET" {1..30}; echo
cut -f1 -d: /etc/passwd | while read user; do
  OUT=$( crontab -u "$user" -l 2>/dev/null )
  if [[ $OUT ]]; then
    echo -e  "$COL_GREEN crontab for $user $COL_RESET"
    printf "$COL_RED%.0s-$COL_RESET" {1..30}; echo
    echo -e "$COL_CYAN minute (0-59), $COL_RESET"
    echo -e "$COL_CYAN |  hour (0-23), $COL_RESET"
    echo -e "$COL_CYAN |  |  day of the month (1-31), $COL_RESET"
    echo -e "$COL_CYAN |  |  |  month of the year (1-12), $COL_RESET"
    echo -e "$COL_CYAN |  |  |  |  day of the week (0-6 with 0=Sunday). $COL_RESET"
    echo -e "$COL_CYAN |  |  |  |  |  command(s) $COL_RESET"
    echo -e "$COL_CYAN |  |  |  |  |  | $COL_RESET"
    echo "$OUT" | grep -v '^#' | grep -v '^$'
    printf "$COL_RED%.0s-$COL_RESET" {1..30}; echo
  fi
done

echo -e "$COL_YELLOW Finished listing crontabs$COL_RESET"
printf "$COL_RED%.0s-$COL_RESET" {1..30}; echo
