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
PASSWORD_FILE="/etc/bareos/backup/.backup-password"
PUBKEY_FILE="/etc/bareos/backup/recipient.pub"
BACKUP_NAME="lto-hwe-keys.gpg"
BACKUP_PATH="/etc/bareos/backup"
BACKUP_SCRIPT="/etc/bareos/scripts/hwe-backup.sh"
DECRYPT_IS_CRITICAL="true"
ETCKEEPER_AUTOCOMMIT="false"
GPG_ENCRYPT_MODE="password"

MAIL_ENABLE="false"
MAIL_ALWAYS="false"
MAIL_HOST="localhost"
MAIL_FROM="(Bareos) <bareos@localhost>"
MAIL_TO="root"
MAIL_SUBJECT="LTO HWE Backup"
MAIL_HEADER=""
MAIL_FOOTER=""

# Make sure required packages are installed and in the current PATH
hash bareos-sd 2>/dev/null || { echo >&2 "You need to install bareos-storage. Aborting."; exit 1; }
hash bscrypto 2>/dev/null || { echo >&2 "You need to install bareos-storage-tape. Aborting."; exit 1; }
hash bsmtp 2>/dev/null || { echo >&2 "You need to install bareos-common. Aborting."; exit 1; }
hash gpg 2>/dev/null || { echo >&2 "You need to install gnupg. Aborting."; exit 1; }

# Enable overriding config file
if [ -n "$1" ]; then
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
BACKUP_CHANGED="false"
SHOULD_SEND_MAIL="false"

if [ -e "${BACKUP_CONFIG_FILE}" ]; then
  source "${BACKUP_CONFIG_FILE}"
fi

CONFIG_PATH="${DIR_CONFIG_PATH}/${DIR_CONFIG_NAME}.conf"
if [ ! -e "${CONFIG_PATH}" ]; then
  echo >&2 "ERROR: Configuration file '${CONFIG_PATH}' could not be found."
  exit 1
fi

if [ ! -e "${BACKUP_SCRIPT}" ]; then
  echo >&2 "ERROR: The specified backup script '${BACKUP_SCRIPT}' does not exist."
  exit 1
fi

encryptModes=([1]=password [2]=publicKey)
if [ -z "${GPG_ENCRYPT_MODE}" ]; then
  echo >&2 "ERROR: No GPG encryption mode specified. Backup aborted."
  exit 1
fi

# Validate selected encryption mode
re='^[0-9]+$'
temp=$GPG_ENCRYPT_MODE
if [[ $temp =~ $re ]] ; then
  temp="${encryptModes[temp]}"
  if [ -z "${temp}" ]; then
    echo >&2 "ERROR: '$GPG_ENCRYPT_MODE' is not mapped to a known encryption mode."
    exit 1
  fi
  GPG_ENCRYPT_MODE="$temp"
else
  if ! echo ${encryptModes[@]} | grep -q -w "$temp"; then
    echo >&2 "ERROR: '$GPG_ENCRYPT_MODE' is not a valid GPG encryption mode."
    exit 1
  fi
fi

# Validate password encryption settings
if [ "${GPG_ENCRYPT_MODE}" == "password" ] && [ ! -e "${PASSWORD_FILE}" ]; then
  echo >&2 "ERROR: Password file '${PASSWORD_FILE}' does not exist."
  exit 1
elif [ "${GPG_ENCRYPT_MODE}" == "publicKey" ] && [ ! -e "${PUBKEY_FILE}" ]; then
  echo >&2 "ERROR: GnuPG public-key file '${PUBKEY_FILE}' does not exist."
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

  if [ -e "${GNUPGHOME}" ]; then
    rm -rf $GNUPGHOME
  fi

  exit 1
}

# Read the current backup (if one exists)
FILE1="${BACKUP_PATH}/${BACKUP_NAME}"
CURRENT=""
DECRYPT_FAILED="false"
if [ "${GPG_ENCRYPT_MODE}" == "password" ] && [ -e "${FILE1}" ]; then
  if ! CURRENT=$(gpg --batch --no-options --passphrase-file="${PASSWORD_FILE}" --homedir="${GNUPGHOME}" --armor --decrypt "${FILE1}" 2>/dev/null); then
    if [ "${DECRYPT_IS_CRITICAL}" != "false" ]; then
      panic "Failed to decrypt previous backup."
    else
      DECRYPT_FAILED="true"
    fi
  fi
else
  DECRYPT_FAILED="true"
fi

# Generate a new backup
if ! NEW=$(${BACKUP_SCRIPT} ${DIR_CONFIG_NAME}); then
  panic "Script '${BACKUP_SCRIPT}' returned a non-zero exit code; backup aborted."
fi

# Check for differences between backups
HEAD_LINES=3
DIFF=$(diff <( echo "${NEW}" | tail -n +${HEAD_LINES}) <(echo "${CURRENT}" | tail -n +${HEAD_LINES}))
if [ -n "${DIFF}" ] || [ "${DECRYPT_FAILED}" == "true" ]; then
  # Backup has changed; update file
  if [ "${DECRYPT_FAILED}" == "true" ]; then
    echo >&2 "Failed to decrypt previous encryption keys backup; re-writing backup..."
  elif [ -n "${DIFF}" ]; then
    echo "Hardware encryption keys backup has changed; writing new backup..."
  fi
  if [ -e "${FILE1}" ]; then
    rm "${FILE1}"
  fi

  if [ "${GPG_ENCRYPT_MODE}" == "password" ]; then
    if ! $(echo "${NEW}" | gpg --batch \
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
                               --output "${FILE1}" > /dev/null 2>&1); then
      panic "Backup password encryption failed; update aborted."
    fi

    BACKUP_CHANGED="true"
  elif [ "${GPG_ENCRYPT_MODE}" == "publicKey" ]; then
    if ! KEY_ID=$(gpg --homedir "${GNUPGHOME}" --keyid-format 0xlong --import "${PUBKEY_FILE}" 2>&1 | grep -Po '(?<=gpg\:\skey\s)[a-zA-Z0-9]+(?=\:\spublic)'); then
      echo >&2 "ERROR: Failed to import public key."
      exit 1
    fi

    if [ -z "${KEY_ID}" ]; then
      echo >&2 "ERROR: Failed to determine GnuPG key identifier."
    else
      echo "Using GnuPG public-key with ID ${KEY_ID} for backup encryption."
    fi

    if ! $(echo "${NEW}" | gpg --batch \
                               --encrypt \
                               --trust-model always \
                               --no-options \
                               --no-emit-version \
                               --no-comments \
                               --digest-algo sha512 \
                               --cipher-algo aes256 \
                               --homedir="${GNUPGHOME}" \
                               --armor \
                               --recipient ${KEY_ID} \
                               --output "${FILE1}" > /dev/null 2>&1); then
      panic "Backup public-key encryption failed; update aborted."
    fi

    BACKUP_CHANGED="true"
  else
    panic "Unsupported GnuPG encryption mode '${GPG_ENCRYPT_MODE}'; update aborted."
  fi

  # git handling for etckeeper (check if /etc/.git exists)
  if [ "${ETCKEEPER_AUTOCOMMIT}" == "true" ] && hash git 2>/dev/null; then
    if $(git -C "/etc" rev-parse > /dev/null 2>&1); then
      if [[ "$(git --git-dir=/etc/.git --work-tree=/etc status --porcelain -- ${FILE1}|grep '^(M| M)')" != "" ]]; then
        pushd /etc > /dev/null 2>&1
        git add "${FILE1}"
        git commit -m "bareos: auto-commit updated backup."
        popd > /dev/null 2>&1
        echo "Committed updated backup file to local /etc Git repository."
      fi
    fi
  fi
else
  echo >&2 "Encryption keys have not changed; backup not updated."
fi

if [ "${MAIL_ALWAYS}" == "true" ] || [ "${BACKUP_CHANGED}" == "true" ]; then
  SHOULD_SEND_MAIL="true"
fi

if [ "${MAIL_ALWAYS}" == "true" ] && [ "${MAIL_ENABLE}" != "true" ]; then
  echo >&2 "WARNING: E-mail not enabled but option to always send e-mails is. Check your settings."
fi

if [ "${MAIL_ENABLE}" == "true" ] && [ "${SHOULD_SEND_MAIL}" == "true" ]; then
  # Send the updated backup file via bsmtp
  sendFailed=0
  if [ -n "${MAIL_HEADER}" ]; then
    if ! $(printf "${MAIL_HEADER}\n\n$(cat ${FILE1})\n\n${MAIL_FOOTER}\n" | bsmtp -h "${MAIL_HOST}" -f "${MAIL_FROM}" -s "${MAIL_SUBJECT}" "${MAIL_TO}"); then
      sendFailed=1
    fi
  elif [ -n "${MAIL_FOOTER}" ]; then
    if ! $(printf "%s\n\n" "$(cat ${FILE1})" "${MAIL_FOOTER}" | bsmtp -h "${MAIL_HOST}" -f "${MAIL_FROM}" -s "${MAIL_SUBJECT}" "${MAIL_TO}"); then
      sendFailed=1
    fi
  else
    if ! $(cat "${FILE1}" | bsmtp -h "${MAIL_HOST}" -f "${MAIL_FROM}" -s "${MAIL_SUBJECT}" "${MAIL_TO}"); then
      sendFailed=1
    fi
  fi
  if ! [ $sendFailed -eq 0 ]; then
    panic "Failed to e-mail hardware encryption keys backup file to ${MAIL_TO}"
  fi
  echo "Sent hardware encryption keys backup via e-mail to ${MAIL_TO}"
else
  echo >&2 "Skipped sending hardware encryption keys backup to ${MAIL_TO}"
fi

# Remove temporary home
if [ -e "${GNUPGHOME}" ]; then
  rm -rf ${GNUPGHOME}
fi

exit 0
