#!/bin/bash
# tests gpg encryption/decryption for the specified key

hash gpg 2>/dev/null || { echo >&2 "You need to install gnupg. Aborting."; exit 1; }

if [[ -z "$1" ]]; then
  echo >&2 "Usage: $0 <key_id>"
  exit 1
fi

KEY_ID="$1"
EXTRA_OPTS="--verbose"
#EXTRA_OPTS="--verbose --debug-all --debug-level guru"

echo "Testing GnuPG key with fingerprint ID $1 ..."
uname -a | gpg ${EXTRA_OPTS} --encrypt --armor --recipient "${KEY_ID}" | gpg ${EXTRA_OPTS} --decrypt --armor

exit 0
