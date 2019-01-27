#!/bin/bash
# [0x19e.net] pulledpork-update.sh
# updates suricata rules using pulledpork
# also handles auto-commit for etckeeper
# configured to use git for version control.
# this script works well as a cronjob.

hash perl 2>/dev/null || { echo >&2 "You need to install perl. Aborting."; exit 1; }
hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }
hash suricata 2>/dev/null || { echo >&2 "You need to install suricata. Aborting."; exit 1; }

# script variables
PULLEDPORK_PLSCRIPT="/usr/local/bin/pulledpork.pl"
PULLEDPORK_CONFFILE="/etc/pulledpork/pulledpork.conf"
SURICATA_RULES_FILE="/etc/suricata/suricata.rules"

# updates require root (unless specially configured)
# if you want to run this script as another user,
# you will need to ensure proper permissions for the
# download folder, output file(s) etc.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# run pulledpork
# note: use -k for separate rule files
perl $PULLEDPORK_PLSCRIPT -T \
  -c $PULLEDPORK_CONFFILE \
  -o $SURICATA_RULES_FILE # -k

# git handling for etckeeper (check if /etc/.git exists)
if `git -C "/etc" rev-parse > /dev/null 2>&1`; then
  # check /etc/suricata for modifications
  # if there are changes under the config folder, commit them
  if [[ "$(git --git-dir=/etc/.git --work-tree=/etc status --porcelain -- /etc/suricata|egrep '^(M| M)')" != "" ]]; then
    echo "Auto-committing updated ruleset..."
    pushd /etc > /dev/null 2>&1
    git add --all /etc/suricata
    git commit -m "suricata: auto-commit updated rules"
    popd > /dev/null 2>&1
  fi
fi

# reload suricata
for x in `pidof "suricata"`; do
  # send live reload signal (USR2)
  echo "Sending live reload signal to suricata pid $x ..."
  kill -USR2 $x
done

exit 0
