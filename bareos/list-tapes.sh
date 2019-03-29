#!/bin/bash
# list tapes using mtx command

AUTOCHANGER="/dev/sg1"

hash mtx 2>/dev/null || { echo >&2 "You need to install mtx. Aborting."; exit 1; }

sudo mtx -f ${AUTOCHANGER} status

exit 0
