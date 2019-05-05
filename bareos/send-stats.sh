#!/bin/bash
# Sends tape drive statistics out using bsmtp

CFG_NAME="send-stats.cfg"

DRIVE="/dev/sg0"
MAIL_HOST="localhost"
MAIL_FROM="(Bareos) <bareos@localhost>"
MAIL_TO="root"
MAIL_SUBJECT="Tape Drive Statistics"

hash bsmtp 2>/dev/null || { echo >&2 "You need to install bareos-common. Aborting."; exit 1; }

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where
  # the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
CWD="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Create some variables for use in configurerd strings
TIME=$(date '+%H:%M:%S%z')
DATE=$(date '+%Y.%m.%d')
TIMESTAMP=$(date '+%Y.%m.%d_%H:%M:%S%z')

CONFIG_PATH="${CWD}/${CFG_NAME}"
if [ -e "${CONFIG_PATH}" ]; then
  source "${BACKUP_CONFIG_FILE}"
fi

# Check if a drive path was supplied
if [ ! -z "$1" ]; then
  DRIVE="$1"
fi
if [ ! -c "${DRIVE}" ]; then
  echo >&2 "ERROR: '$1' is not a valid block device."
  exit 1
fi

# Configure the stats command
STATS_COMMAND="${CWD}/drive-stats.sh ${DRIVE}"

# Get statistics
if ! STATS="$(${STATS_COMMAND})"; then
  echo >&2 "ERROR: Failed to run stats command '${STATS_COMMAND}'."
  exit 1
fi
if [ -z "${STATS}" ]; then
  echo >&2 "ERROR: Statistics output is null."
  exit 1
fi

# Send the message
if ! echo "${STATS}" | bsmtp -h "${MAIL_HOST}" -f "${MAIL_FROM}" -s "${MAIL_SUBJECT}" "${MAIL_TO}"; then
  echo >&2 "ERROR: Failed to e-mail statistics to ${MAIL_TO}."
  exit 1
fi

echo "Sent tape drive statistics to ${MAIL_TO}."
exit 0
