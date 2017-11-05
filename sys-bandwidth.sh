#!/bin/bash
# read 32GB zero's and throw them away.
# rwb[at]0x19e[dot]net

dd if=/dev/zero of=/dev/null bs=1M count=$((32*1024))
