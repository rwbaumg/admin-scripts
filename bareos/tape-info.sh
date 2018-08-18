#!/bin/bash

DRIVE="/dev/nst0"

tapeinfo -f ${DRIVE} && echo && bscrypto -e ${DRIVE}
