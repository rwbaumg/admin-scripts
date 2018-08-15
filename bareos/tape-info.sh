#!/bin/bash

tapeinfo -f /dev/st0 && echo && bscrypto -e /dev/st0
