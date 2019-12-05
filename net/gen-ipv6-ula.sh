#!/bin/bash
# Generate a IPv6 Unique Local Address

r1=$(dd if=/dev/urandom bs=1 count=1 2>/dev/null | hexdump -e '1/1 "%02x"')
r2=$(dd if=/dev/urandom bs=2 count=1 2>/dev/null | hexdump -e '2/1 "%02x"')
r3=$(dd if=/dev/urandom bs=2 count=1 2>/dev/null | hexdump -e '2/1 "%02x"')

echo "ULA prefix: fd$r1:$r2:$r3::/48"

exit 0
