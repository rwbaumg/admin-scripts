#!/bin/sh

[ "$(uci -q get network.globals.ula_prefix)" != "auto" ] && echo >&2 "ula_prefix is not set to auto." && exit 0

r1=$(dd if=/dev/urandom bs=1 count=1 2>/dev/null | hexdump -e '1/1 "%02x"')
r2=$(dd if=/dev/urandom bs=2 count=1 2>/dev/null | hexdump -e '2/1 "%02x"')
r3=$(dd if=/dev/urandom bs=2 count=1 2>/dev/null | hexdump -e '2/1 "%02x"')

echo "New ULA prefix: fd$r1:$r2:$r3::/48"

uci -q batch <<-EOF >/dev/null
	set network.globals.ula_prefix=fd$r1:$r2:$r3::/48
	commit network
EOF

exit 0
