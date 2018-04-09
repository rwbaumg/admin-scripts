#!/bin/bash
# deletes a keypair from gpg

if [[ -z "$1" ]]; then
  echo >&2 "Usage: $0 <key_id>"
  exit 1
fi

echo "Trying to delete GnuPG key with fingerprint ID $1 ..."

gpg --delete-secret-key $1
gpg --delete-key $1

exit 0
