#!/bin/bash
# Initializes a new Maildir folder for the specified user

USER=$1

MAILDIR_PATH=/home/${USER}/Maildir

echo "Creating Maildir folder $MAILDIR_PATH ..."

maildirmake.dovecot ${MAILDIR_PATH}
maildirmake.dovecot ${MAILDIR_PATH}/.Drafts
maildirmake.dovecot ${MAILDIR_PATH}/.Sent
maildirmake.dovecot ${MAILDIR_PATH}/.Junk
maildirmake.dovecot ${MAILDIR_PATH}/.Trash
maildirmake.dovecot ${MAILDIR_PATH}/.Templates

maildirmake.dovecot ${MAILDIR_PATH}/virtual

chmod 700 ${MAILDIR_PATH}
chmod -R 770 ${MAILDIR_PATH}/

chown -R ${USER}: ${MAILDIR_PATH}

exit 0
