#!/bin/bash
# restarts the gpg agent
# useful for when a gpg mfd like a yubikey gets locked

hash gpg-connect-agent 2>/dev/null || { echo >&2 "You need to install gpgconf. Aborting."; exit 1; }

gpg-connect-agent killagent /bye
gpg-connect-agent /bye

exit 0
