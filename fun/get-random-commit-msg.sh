#!/bin/bash
# Print a random commit message from whatthecommit.com

hash curl 2>/dev/null || { echo >&2 "You need to install curl. Aborting."; exit 1; }

curl -s http://whatthecommit.com/index.txt

exit $?
