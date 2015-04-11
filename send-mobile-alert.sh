#!/bin/bash
# script to send an alert text
# rwb [ rwb[at]0x19e.net ]

if [[ -z "$1" ]]; then
  echo "Usage: $0 [opts]"
  exit 1
fi

# Path to FFMpeg binary
FFMPEG_BIN="/usr/bin/ffmpeg"

# The maximum attachment size (in KB)
ATTACHMENT_MAX_SIZE=1024

MOBILE=""
NOW=$(date +"%m-%d-%Y %r")
ATTACHMENT=""
FORCE_MMS=""

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
  -a|--attachment)
    if [[ ! -z "$2" ]]; then
      if [ ! -f "$2" ]; then
        echo "Specified file not found!"
        exit 1
      fi
      if [ ${2: -4} == ".jpg" ] || [ ${2: -4} == ".avi" ]; then
        echo "Setting attachment file to $2"
        ATTACHMENT="$2"

        # check attachment size and if needed try to compress it down
        # before trying to send (the MMS gateway will just scrub the
        # attachment otherwise)
        filesize=$(du -k "$2" | cut -f 1)
        if [ $filesize -ge $ATTACHMENT_MAX_SIZE ]; then
          echo "Specified attachment is too large"
          if [ ${2: -4} == ".avi" ]; then
            if [ ! -f "$FFMPEG_BIN" ]; then
              echo "Fatal error: could not locate ffmpeg binary at '$FFMPEG_BIN'"
              exit 1
            fi
            duration=$($FFMPEG_BIN -i "$2" 2>&1 | grep Duration | cut -d ' ' -f 4 | cut -d '.' -f 1)
            len_s=$(date +'%s' -d "$duration")
            bitrate=$(((($ATTACHMENT_MAX_SIZE / 1024) * 1024 * 1024) / len_s * 8))
            # bitrate=$(((($ATTACHMENT_MAX_SIZE * 1024) / len_s) * 8))
            echo "Calculated a required birate of $bitrate for video length of $len_s second(s)."
            compressed_name="$2.small.avi"
            if [ ! -f "$compressed_name" ]; then
              echo "Compressing video stream to '$compressed_name' using '$FFMPEG_BIN' ..."
              $FFMPEG_BIN -i "$2" \
                          -s 320x240 \
                          -b:v $bitrate \
                          -r "15" \
                          -vcodec mpeg4 \
                          "$compressed_name"
            fi
            # use compressed attachment
            ATTACHMENT="$compressed_name"
          else
            echo "Cannot compress filetype '${2: -4}' and it is too large to send, nothing left to do."
            exit 1
          fi
        fi
      else
        echo "Specified attachment not supported by MMS: $2"
        exit 1
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
  --force-mms)
    echo "FORCE_MMS set to true"
    FORCE_MMS="yes"
    # shift
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
if [ -n "$FORCE_MMS" ] || [ -n "$ATTACHMENT" ]; then
  echo "Sending message using MMS gateway..."
  if [[ -z "$ATTACHMENT" ]]; then
    echo -e "$MESSAGE"|mailx -v \
    -r "$MAIL_FROM" \
    -s "$SUBJECT" \
    -S smtp="$SMTP_SERVER" \
    -S smtp-use-starttls \
    "$MOBILE@$MMS_GATEWAY"
  else
    echo -e "$MESSAGE"|mailx -v -a "$ATTACHMENT" \
    -r "$MAIL_FROM" \
    -s "$SUBJECT" \
    -S smtp="$SMTP_SERVER" \
    -S smtp-use-starttls \
    "$MOBILE@$MMS_GATEWAY"
  fi
else
  echo "Sending message using TXT gateway..."
  echo -e "$MESSAGE"|mailx -v \
  -r "$MAIL_FROM" \
  -s "$SUBJECT" \
  -S smtp="$SMTP_SERVER" \
  -S smtp-use-starttls \
  "$MOBILE@$TXT_GATEWAY"
fi
