#!/bin/bash
# List commands provided by the specified package
# rwb[at]0x19e[dot]net

# todo: fix multiline support (ie. 'lspgpot' command from 'gnupg' package contains multiple lines)

BIN_REGEX="(sbin|bin)\/"

if [ -z "$1" ]; then
  echo >&2 "No package specified."
  exit 1
fi

if ! dpkg -s "$1" > /dev/null 2>&1; then
  echo >&2 "Package '$1' is not installed."
  exit 1
fi

if ! dpkg -L "$1" | grep  --quiet -P "$BIN_REGEX"; then
  echo >&2 "Package '$1' does not appear to install any commands."
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

# print table header
printf "%s" "$COL_RESET"
printf '=%.0s' {1..60}
printf '\n'
printf "$COL_RED%-29s %s \n$COL_RESET" "Command" "Description"
printf '=%.0s' {1..60}
printf '\n'
printf "%s" "$COL_RESET"

for d in $(dpkg -L "$1" | grep -P "$BIN_REGEX" | sort); do \
  man_header=$(man -P cat "$(basename "$d")" 2>/dev/null | grep NAME -A1 | head -2 | tail -n1 )
  man_synopsis=$(man -P cat "$(basename "$d")" 2>/dev/null | grep SYNOPSIS -A1 | head -2 | tail -1)

  # remove leading whitespace and escape special characters
  man_synopsis=$(echo "$man_synopsis" | sed -e 's/^[ \t]*//')
  # man_synopsis=$(echo "$man_synopsis" | sed -e 's/[]\/$*.^[]/\\&/g')

  if [ -n "$man_header" ]; then
    echo "$man_header" | awk -v synop="$man_synopsis" -v x=0 -v N=2 'BEGIN {RS="\n\n"}; {OFS="\b"}; {FS="\b+(-|—)\b+"};
    function print_command(string) {  printf ("%s%-30s%s", "\033[1;36m", string, "\033[0m"); }
    function print_synopsis(string) { printf ("%80s%s%s", "\033[1;36m", string, "\033[0m"); }
    function start_yellow() { printf ("%s", "\033[1;33m"); }
    function stop_yellow() { printf ("%s", "\033[0m"); }
    {
      print_command($1);
      start_yellow();
      OFS=" "; sep=""; for (i=N+1; i<=NF; i++) {
        printf("%s%s",sep,$i);
        sep=OFS
        x=x+1
      };
      stop_yellow();
      # print_synopsis(synop);
      printf("\n");
      x=0;
    }'; \
  fi
done

exit 0
