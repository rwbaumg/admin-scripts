#!/bin/bash
# restarts the gpg agent
# useful for when a gpg mfd like a yubikey gets locked

# hash gnupg 2>/dev/null || { echo >&2 "You need to install gnupg. Aborting."; exit 1; }

gpg-connect-agent killagent /bye
gpg-connect-agent /bye

exit 0
