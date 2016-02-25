#!/bin/bash
# sshd-keygen.sh
# post-apply script that properly manages ssh authentication keys
# Install in /var/radmind/postapply

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

SSHKEYGEN=/usr/bin/ssh-keygen
RSA_BITS=2048
COMMENT=""

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

printf "$COL_GREEN%s$COL_RESET\n" "First-time key generation for SSH daemon"
printf "$COL_CYAN%s$COL_RESET\n" "NOTE: This will not replace existing keys!"
printf "$COL_BLUE%.0s-$COL_RESET" {1..40}; echo

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    printf "$COL_YELLOW%s$COL_RESET\n" "Using $RSA_BITS bits for new RSA key..."
    $SSHKEYGEN -t rsa -b $RSA_BITS -f /etc/ssh/ssh_host_rsa_key -N "" \
        -C "$COMMENT" < /dev/null # > /dev/null 2> /dev/null
    printf "$COL_GREEN%s$COL_RESET\n" "Created /etc/ssh_host_rsa_key"
else
    printf "$COL_RED%s$COL_RESET\n" "Key already exists: /etc/ssh/ssh_host_rsa_key"
fi

if [ ! -f /etc/ssh/ssh_host_dsa_key ]; then
    printf "$COL_YELLOW%s$COL_RESET\n" "Using 1024 bits for new DSA key..."
    $SSHKEYGEN -t dsa -b 1024 -f /etc/ssh/ssh_host_dsa_key -N "" \
        -C "$COMMENT" < /dev/null # > /dev/null 2> /dev/null
    printf "$COL_GREEN%s$COL_RESET\n" "Created /etc/ssh_host_dsa_key"
else
    printf "$COL_RED%s$COL_RESET\n" "Key already exists: /etc/ssh/ssh_host_dsa_key"
fi

# printf "$COL_BLUE%.0s-$COL_RESET" {1..40}; echo

exit 0
