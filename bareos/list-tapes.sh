#!/bin/bash
# list tapes using mtx command

AUTOCHANGER="/dev/sg1"

sudo mtx -f ${AUTOCHANGER} status

exit 0
