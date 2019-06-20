#!/bin/bash

# one-liner
start_date=$(date +%s); while true; do echo -ne "$(date -u --date @$(($(date +%s) - start_date)) +%H:%M:%S)\r"; done

exit 0
