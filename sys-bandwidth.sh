#!/bin/bash
# read 32GB zero's and throw them away.
# rwb[at]0x19e[dot]net

SIZE_MB=32

dd if=/dev/zero of=/dev/null bs=1M count=$((SIZE_MB*1024))
# dd if=/dev/zero bs=1M count=$((SIZE_MB*1024)) | pv -brtep -s "${SIZE_MB}m" | dd of=/dev/null

exit 0
