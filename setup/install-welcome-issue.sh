#!/bin/bash
# writes a custom message in /etc/issue
# rwb[at]0x19e[dot]net

ipaddress=$(ifconfig | grep inet | awk 'NR==1 {print $2}' | awk 'BEGIN { FS=":" } { print $2 }')

# create simple /etc/issue banner
banner='\n \l'
echo "$banner" > /etc/issue
echo "IP Address: $ipaddress" >> /etc/issue

RANGE=3
number=$((RANDOM%=RANGE))
case $number in
    0)
        cow="tux"
        ;;
    1)
        cow="koala"
        ;;
    2)
        cow="moose"
        ;;
esac

RANGE=2
number=$((RANDOM%=RANGE))
case $number in
    0)
        command="/usr/games/cowsay"
        ;;
    1)
        command="/usr/games/cowthink"
        ;;
esac

# Add to /etc/issue
/usr/games/fortune -s | $command -f $cow | sed 's:\\:\\\\:g' >> /etc/issue

# Add to /etc/issue.net
echo '<hostname>' > /etc/issue.net
/usr/games/fortune -s | $command -f $cow >> /etc/issue.net

exit 0
