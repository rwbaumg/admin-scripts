#!/bin/bash
# script to send an alert text
# rwb [ rwb[at]0x19e.net ]

if [[ -z "$1" ]]; then
  echo "Usage: $0 [opts]"
  exit 1
fi

MOBILE=""
NOW=$(date +"%m-%d-%Y %r")
IMAGE=""

# The SMTP server to use for sending e-mails (must have STARTTLS turned on)
SMTP_SERVER="mail.0x19e.net:587"

# The gateway (last part of the e-mail address) used for sending mobile text messages.
# This is the preferred gateway when no image attachment is specified, and is usually 
# faster than sending a message via an MMS gateway.
TXT_GATEWAY="txt.att.net"

# The gateway (last part of the e-mail address) used for sending mobile multi-media messages.
# This gateway is used when sending messages with an attached picture.
MMS_GATEWAY="mms.att.net"

# The e-mail address the message should appear to be from.
MAIL_FROM="security@0x19e.net"

# The subject of the alert.
SUBJECT="SECURITY ALERT"

# The message for the alert (processed using 'echo -e').
# Environment variables:
# Name        Value
# ============================
# $NOW        The current date and time, in the format "%m-%d-%Y %r"
# $MOBILE     The mobile phone number the alert is being sent to.
MESSAGE="A security related event was detected on $NOW \n Action may be required."

while [[ $# > 1 ]]
do
key="$1"

case $key in
  -n|--mobile-number)
    MOBILE="$2"
    echo "Mobile number set to: $MOBILE"
    shift
  ;;
  -s|--subject)
    SUBJECT="$2"
    echo "Subject set to: $SUBJECT"
    shift
  ;;
  -m|--message)
    if [[ -z "$2" ]]; then
      echo "You must supply a message along with the -m|--message option."
      exit 1
    fi
    MESSAGE=$(echo -e "$2")
    echo "Message set to: $MESSAGE"
    shift
  ;;
  -f|--mail-from)
    MAIL_FROM="$2"
    echo "MAIL_FROM set to: $MAIL_FROM"
    shift
  ;;
  -i|--image)
    if [[ ! -z "$2" ]]; then
      if [ ! -f "$2" ]; then
        echo "Specified image not found!"
        exit 1
      fi
      if [ ${2: -4} == ".jpg" ]; then
        echo "Setting image file to $2"
        IMAGE="$2"
      fi
    fi
    shift
  ;;
  --mms-gateway)
    echo "MMS_GATEWAY set to: $2"
    MMS_GATEWAY="$2"
    shift
  ;;
  --txt-gateway)
    echo "TXT_GATEWAY set to: $2"
    MMS_GATEWAY="$2"
    shift
  ;;
  --smtp-server)
    echo "SMTP_SERVER set to: $2"
    SMTP_SERVER="$2"
    shift
  ;;
  *)
    # unknown option
    echo "Unknown option: $2"
  ;;
esac
shift
done

if [[ -z "$MOBILE" ]]; then
  echo "A mobile number way not supplied."
  exit 1
fi

# Send the alert using the mailx command.
if [[ -z "$IMAGE" ]]; then
  echo -e "$MESSAGE"|mailx -v \
  -r "$MAIL_FROM" \
  -s "$SUBJECT" \
  -S smtp="$SMTP_SERVER" \
  -S smtp-use-starttls \
  "$MOBILE@$TXT_GATEWAY"
else
  echo -e "$MESSAGE"|mailx -v -a "$IMAGE" \
  -r "$MAIL_FROM" \
  -s "$SUBJECT" \
  -S smtp="$SMTP_SERVER" \
  -S smtp-use-starttls \
  "$MOBILE@$MMS_GATEWAY"
fi
