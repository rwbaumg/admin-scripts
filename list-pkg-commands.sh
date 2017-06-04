#!/bin/bash
# List commands provided by the specified package
# rwb[at]0x19e[dot]net

if [ ! `dpkg -s $1 > /dev/null 2>&1` ]; then
  echo >&2 "Package '$1' is not installed."
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

# print table header
printf "$COL_RESET"
printf '=%.0s' {1..50}
printf '\n'
printf "$COL_RESET%-20s %s \n$COL_RESET" "Command" "Description"
printf '=%.0s' {1..50}
printf '\n'
printf "$COL_RESET"

for d in `dpkg -L $1 | grep bin/ | sort`; do \
  echo $(man -P cat $d 2>/dev/null | grep NAME -A1 | head -2 | tail -n1 ) \
    | awk -F' - ' -v N=2 'BEGIN {OFS=" "}; { \
      printf("%-20s", $1); \
      OFS=" "; sep=""; for (i=N; i<=NF; i++) { \
        printf("%s%s",sep,$i); sep=OFS }; \
        printf("\n"); } \
    ' ; \
  done
