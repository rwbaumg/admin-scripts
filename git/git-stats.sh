#!/bin/bash
# Print Git statistics
#
# Some other useful commands:
#
# Per-user line contributions:
#  git ls-files | xargs -n1 -d'\n' -i git-blame {} | perl -n -e '/\s\((.*?)\s[0-9]{4}/ && print "$1\n"' | sort -f | uniq -c -w3 | sort -r
#
# Get commit history for local repository:
#  git reflog show | grep '}: commit' | nl | sort -nr | nl | sort -nr | cut --fields=1,3 | sed s/commit://g | sed -e 's/HEAD*@{[0-9]*}://g'
#
# List all branches, sorted by date modified:
#  for k in `git branch|perl -pe s/^..//`;do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue(%cr%Creset)" $k|head -n 1` : $k;done|sort -r
#
# List all contributors:
#  git log --format='%aN' | sort -u
#

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

if ! `git -C . rev-parse`; then
  echo >&2 "Directory does not appear to be a valid Git repository."
  exit 1
fi

git log --shortstat \
  | grep -E "fil(e|es) changed" \
  | awk '{files+=$1; inserted+=$4; deleted+=$6; delta+=$4-$6; ratio=deleted/inserted} END {printf "Commit stats:\n- Files changed (total)..  %s\n- Lines added (total)....  %s\n- Lines deleted (total)..  %s\n- Total lines (delta)....  %s\n- Add./Del. ratio (1:n)..  1 : %s\n", files, inserted, deleted, delta, ratio }'

exit $?
