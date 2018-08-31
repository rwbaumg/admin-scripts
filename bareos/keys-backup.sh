#!/bin/bash
#
# -=[ 0x19e Networks ]=-
#
# Creates a backup of LTO hardware encryption keys used
# by the Bareos storage daemon.
#
# Path to an optional configuration file
BACKUP_CONFIG_FILE="/etc/bareos/keys-backup.cfg"

# Default settings
DIR_CONFIG_NAME="bareos-dir"
DIR_CONFIG_PATH="/etc/bareos/bareos-sd.d/director"
PASSWORD_FILE="/etc/bareos/.backup/.backup-password"
BACKUP_NAME="lto-hwe-keys.gpg"
BACKUP_PATH="/etc/bareos/.backup"
BACKUP_SCRIPT="/etc/bareos/scripts/hwe-backup.sh"
DECRYPT_IS_CRITICAL="true"
ETCKEEPER_AUTOCOMMIT="false"

MAIL_ENABLE="false"
MAIL_HOST="localhost"
MAIL_FROM="(Bareos) <bareos@localhost>"
MAIL_TO="root"
MAIL_SUBJECT="New LTO HWE Backup"
MAIL_HEADER=""
MAIL_FOOTER=""

# Make sure required packages are installed and in the current PATH
hash bscrypto 2>/dev/null || { echo >&2 "You need to install bareos-storage-tape. Aborting."; exit 1; }
hash bsmtp 2>/dev/null || { echo >&2 "You need to install bareos-common. Aborting."; exit 1; }
hash gpg 2>/dev/null || { echo >&2 "You need to install gnupg. Aborting."; exit 1; }

# Enable overriding config file
if [ ! -z "$1" ]; then
  if [ ! -e "$1" ]; then
    echo >&2 "ERROR: The specified configuration file '$1' does not exist."
    exit 1
  fi

  BACKUP_CONFIG_FILE="$1"
fi

# Create some variables for use in configurerd strings
TIME=$(date '+%H:%M:%S%z')
DATE=$(date '+%Y.%m.%d')
TIMESTAMP=$(date '+%Y.%m.%d_%H:%M:%S%z')

if [ -e "${BACKUP_CONFIG_FILE}" ]; then
  source "${BACKUP_CONFIG_FILE}"
fi

CONFIG_PATH="${DIR_CONFIG_PATH}/${DIR_CONFIG_NAME}.conf"
if [ ! -e "${CONFIG_PATH}" ]; then
  echo >&2 "ERROR: Configuration file '${CONFIG_PATH}' could not be found."
  exit 1
fi

# NOTE: This password is used to encrypt the backup.
if [ ! -e "${PASSWORD_FILE}" ]; then
  echo >&2 "ERROR: Password file '${PASSWORD_FILE}' does not exist."
  exit 1
fi

# Create a temporary home directory
GNUPGHOME=$(mktemp -d /tmp/.gnupgXXXXXX)

function panic()
{
  local msg="$1"
  if [ -z "${msg}" ]; then
    msg="Unknown failure."
  fi

  # Remove temporary home and exit.
  echo >&2 "ERROR: ${msg}"
  echo >&2 "ERROR: Failed to decrypt previous backup."
  rm -rf $GNUPGHOME
  exit 1
}

# Read the current backup (if one exists)
FILE1="${BACKUP_PATH}/${BACKUP_NAME}"
CURRENT=""
DECRYPT_FAILED="false"
if [ -e "${FILE1}" ]; then
  CURRENT=$(echo "${GPG_PASSWORD}" | gpg --batch --no-options --passphrase-file="${PASSWORD_FILE}" --homedir="${GNUPGHOME}" --armor --decrypt "${FILE1}" 2>/dev/null)
  if ! [ $? -eq 0 ]; then
    if [ "${DECRYPT_IS_CRITICAL}" == "false" ]; then
      panic "Failed to decrypt previous backup."
    else
      DECRYPT_FAILED="true"
    fi
  fi
fi

# Generate a new backup
NEW=$(${BACKUP_SCRIPT} ${DIR_CONFIG_NAME})

# Check for differences between backups
HEAD_LINES=3
DIFF=$(diff <( echo "${NEW}" | tail -n +${HEAD_LINES}) <(echo "${CURRENT}" | tail -n +${HEAD_LINES}))
if [ ! -z "${DIFF}" ] || [ "${DECRYPT_FAILED}" == "true" ]; then
  # Backup has changed; update file
  if [ -e "${FILE1}" ]; then
    rm "${FILE1}"
  fi
  echo "${NEW}" | gpg --batch \
                      --no-options \
                      --no-emit-version \
                      --no-comments \
                      --passphrase-file="${PASSWORD_FILE}" \
                      --homedir="${GNUPGHOME}" \
                      --symmetric \
                      --force-mdc \
                      --armor \
                      --s2k-cipher-algo aes256 \
                      --s2k-digest-algo sha512 \
                      --s2k-mode 3 \
                      --s2k-count 65000000 \
                      --output "${FILE1}" > /dev/null 2>&1

  if ! [ $? -eq 0 ]; then
    panic "Backup encryption failed; update aborted."
  fi

  # git handling for etckeeper (check if /etc/.git exists)
  if [ "${ETCKEEPER_AUTOCOMMIT}" == "true" ]; then
    if `git -C "/etc" rev-parse > /dev/null 2>&1`; then
      if [[ "$(git --git-dir=/etc/.git --work-tree=/etc status --porcelain -- ${FILE1}|egrep '^(M| M)')" != "" ]]; then
        pushd /etc > /dev/null 2>&1
        git add "${FILE1}"
        git commit -m "bareos: auto-commit updated backup."
        popd > /dev/null 2>&1
      fi
    fi
  fi

  # Send the updated backup file via bsmtp
  if [ "${MAIL_ENABLE}" == "true" ]; then
    if [ ! -z "${MAIL_HEADER}" ]; then
      printf "${MAIL_HEADER}\n\n$(cat ${FILE1})\n\n${MAIL_FOOTER}\n" | bsmtp -h "${MAIL_HOST}" -f "${MAIL_FROM}" -s "${MAIL_SUBJECT}" "${MAIL_TO}"
    elif [ ! -z "${MAIL_FOOTER}" ]; then
      printf "%s\n\n" "$(cat ${FILE1})" "${MAIL_FOOTER}" | bsmtp -h "${MAIL_HOST}" -f "${MAIL_FROM}" -s "${MAIL_SUBJECT}" "${MAIL_TO}"
    else
      cat "${FILE1}" | bsmtp -h "${MAIL_HOST}" -f "${MAIL_FROM}" -s "${MAIL_SUBJECT}" "${MAIL_TO}"
    fi
    if ! [ $? -eq 0 ]; then
      panic "Failed to e-mail backup file."
    fi
  fi
fi

# Remove temporary home
rm -rf $GNUPGHOME

exit 0
