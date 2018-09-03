#!/bin/bash
# script to send an alert text
# rwb [ rwb[at]0x19e.net ]

# Path to FFMpeg binary
FFMPEG_BIN="/usr/bin/ffmpeg"

# The maximum attachment size (in KB)
ATTACHMENT_MAX_SIZE=1024

MOBILE=""
NOW=$(date +"%m-%d-%Y %r")
ATTACHMENT=""
FORCE_MMS=""
MAIL_ARGS=""
VERBOSE_SWITCH=""
VERBOSITY=0

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

exit_script()
{
    # Default exit code is 1
    local exit_code=1
    local re var

    re='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'
    if echo "$1" | egrep -q "$re"; then
        exit_code=$1
        shift
    fi

    re='[[:alnum:]]'
    if echo "$@" | egrep -iq "$re"; then
        echo
        if [ $exit_code -eq 0 ]; then
            echo "INFO: $@"
        else
            echo "ERROR: $@" 1>&2
        fi
    fi

    # Print 'aborting' string if exit code is not 0
    [ $exit_code -ne 0 ] && echo "Aborting script..."

    exit $exit_code
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename $0)|" \
                       -e "s|MMS_GATEWAY|$MMS_GATEWAY|" \
                       -e "s|TXT_GATEWAY|$TXT_GATEWAY|" \
                       -e "s|SMTP_SERVER|$SMTP_SERVER|" \
                       -e "s|MAIL_FROM|$MAIL_FROM|" \
                       -e "s|SUBJECT|$SUBJECT|" \
        <<"    EOF"
    USAGE

    Send a message to a mobile device.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS

     -n, --mobile-number <value>   The mobile number to send an alert to.
     -f, --mail-from <value>       Sets the sender property for the message. (default: MAIL_FROM)
     -s, --subject <value>         The message subject. (default: SUBJECT)
     -m, --message <value>         The message body.

     -a, --attachment <value>      Adds a media attachement to the message. Videos
                                   will be compressed to the required size.

     --mms-gateway <value>         Sets the MMS gateway to use for sending MMS messages. (default: MMS_GATEWAY)
     --txt-gateway <value>         Sets the TXT gateway to use for sending text messages. (default: TXT_GATEWAY)
     --smtp-server <value>         Sets the SMTP server for sending e-mail alerts. (default: SMTP_SERVER)
     --force-mms                   Send the message using MMS, event if it only contains text.

     -v, --verbose                 Make the script more verbose. This option can be specified multiple times.
     -h, --help                    Prints this usage.
    EOF

    exit_script $@
}

test_arg()
{
    # Used to validate user input
    local arg="$1"
    local argv="$2"

    if [ -z "$argv" ]; then
        if echo "$arg" | egrep -q '^-'; then
            usage "Null argument supplied for option $arg"
        fi
    fi

    if echo "$argv" | egrep -q '^-'; then
        usage "Argument for option $arg cannot start with '-'"
    fi
}

# verify required programs
hash mailx 2>/dev/null || { echo >&2 "You need to install mailx. Aborting."; exit 1; }

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
case "$1" in
  -n|--mobile-number)
    test_arg "$1" "$2"
    shift
    MOBILE="$1"
    shift
  ;;
  -s|--subject)
    test_arg "$1" "$2"
    shift
    SUBJECT="$1"
    shift
  ;;
  -m|--message)
    test_arg "$1" "$2"
    shift
    MESSAGE=$(echo -e "$1")
    shift
  ;;
  -f|--mail-from)
    test_arg "$1" "$2"
    shift
    MAIL_FROM="$1"
    shift
  ;;
  -a|--attachment)
    test_arg "$1" "$2"
    shift
    if [[ ! -z "$1" ]]; then
      if [ ! -f "$1" ]; then
        echo >&2 "ERROR: Specified attachment file not found!"
        exit 1
      fi

      filename=$(basename -- "$1")
      extension="${filename##*.}"
      filename="${filename%.*}"

      if [ "${extension}" == "jpg" ] || [ "${extension}" == "avi" ]; then
        # echo "Setting attachment file to $1 ..."
        ATTACHMENT=$1
        ATTACHMENT_EXT=${extension}

        # check attachment size and if needed try to compress it down
        # before trying to send (the MMS gateway will just scrub the
        # attachment otherwise)
        filesize=$(du -k "$ATTACHMENT" | cut -f 1)
        if [ $filesize -ge $ATTACHMENT_MAX_SIZE ]; then
          if [ $VERBOSITY -gt 0 ]; then
            echo >&2 "WARNING: Specified attachment is too large"
          fi
          if [ "$ATTACHMENT_EXT" == ".avi" ]; then
            if [ ! -f "$FFMPEG_BIN" ]; then
              echo >&2 "FATAL: could not locate ffmpeg binary at '$FFMPEG_BIN'"
              exit 1
            fi

            # calculate required bitrate to compress video to supported size
            duration=$($FFMPEG_BIN -i "$ATTACHMENT" 2>&1 | grep Duration | cut -d ' ' -f 4 | cut -d '.' -f 1)
            len_s=$(date +'%s' -d "$duration")
            bitrate=$(((($ATTACHMENT_MAX_SIZE / 1024) * 1024 * 1024) / len_s * 8))
            # bitrate=$(((($ATTACHMENT_MAX_SIZE * 1024) / len_s) * 8))
            if [ $VERBOSITY -gt 0 ]; then
              echo "Calculated a required birate of $bitrate for video length of $len_s second(s)."
            fi

            compressed_name="$ATTACHMENT.small.avi"
            if [ ! -f "$compressed_name" ]; then
              if [ $VERBOSITY -gt 0 ]; then
                echo "Compressing video stream to '$compressed_name' using '$FFMPEG_BIN' ..."
              fi

              # invoke ffmpeg to compress video attachment
              $FFMPEG_BIN -i "$ATTACHMENT" \
                          -s 320x240 \
                          -b:v $bitrate \
                          -r "15" \
                          -vcodec mpeg4 \
                          "$compressed_name"
            fi

            # use compressed attachment
            ATTACHMENT="$compressed_name"
          else
            echo >&2 "ERROR: Cannot compress filetype '$ATTACHMENT_EXT' and it is too large to send, nothing left to do."
            exit 1
          fi
        fi
      else
        echo >&2 "ERROR: Specified attachment not supported by MMS: $1"
        exit 1
      fi
    fi
    shift
  ;;
  --mms-gateway)
    test_arg "$1" "$2"
    shift
    MMS_GATEWAY="$1"
    shift
  ;;
  --txt-gateway)
    test_arg "$1" "$2"
    shift
    TXT_GATEWAY="$1"
    shift
  ;;
  --smtp-server)
    test_arg "$1" "$2"
    shift
    SMTP_SERVER="$1"
    shift
  ;;
  --force-mms)
    FORCE_MMS="yes"
    shift
  ;;
  -v|--verbose)
    ((VERBOSITY++))
    VERBOSE_SWITCH="-v"
    shift
  ;;
  -h|--help)
    usage
  ;;
  *)
    # unknown option
    echo "Unknown option: $1"
    shift
  ;;
esac
done

if [[ -z "$MOBILE" ]]; then
  echo >&2 "A mobile number way not supplied."
  exit 1
fi

if [ $VERBOSITY -gt 0 ]; then
  echo MOBILE NUMBER = "${MOBILE}"
  echo SUBJECT       = "${SUBJECT}"
  echo MESSAGE       = "${MESSAGE}"
  echo MAIL FROM     = "${MAIL_FROM}"
  echo MMS GATEWAY   = "${MMS_GATEWAY}"
  echo TXT GATEWAY   = "${TXT_GATEWAY}"
  echo SMTP SERVER   = "${SMTP_SERVER}"
  echo FORCE MMS     = "${FORCE_MMS}"
  echo ATTACHMENT    = "${ATTACHMENT}"
  echo VERBOSITY     = "${VERBOSITY}"
fi

# Send the alert using the mailx command.
MAIL_ARGS="$VERBOSE_SWITCH"
if [ -n "$FORCE_MMS" ] || [ -n "$ATTACHMENT" ]; then
  echo "Sending message using MMS gateway..."
  if [[ -z "$ATTACHMENT" ]]; then
    echo -e "$MESSAGE"|mailx $MAIL_ARGS \
    -r "$MAIL_FROM" \
    -s "$SUBJECT" \
    -S smtp="$SMTP_SERVER" \
    -S smtp-use-starttls \
    "$MOBILE@$MMS_GATEWAY"
  else
    echo -e "$MESSAGE"|mailx $MAIL_ARGS -a "$ATTACHMENT" \
    -r "$MAIL_FROM" \
    -s "$SUBJECT" \
    -S smtp="$SMTP_SERVER" \
    -S smtp-use-starttls \
    "$MOBILE@$MMS_GATEWAY"
  fi
else
  echo "Sending message using TXT gateway..."
  echo -e "$MESSAGE"|mailx $MAIL_ARGS \
  -r "$MAIL_FROM" \
  -s "$SUBJECT" \
  -S smtp="$SMTP_SERVER" \
  -S smtp-use-starttls \
  "$MOBILE@$TXT_GATEWAY"
fi
