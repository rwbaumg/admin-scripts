#!/bin/bash
# matrix-style animation
# rwb[at]0x19e[dot]net

tr -c "[:digit:]" " " < /dev/urandom \
| dd cbs="$(tput cols)" conv=unblock \
| GREP_COLOR="1;32" grep --color "[^ ]"
