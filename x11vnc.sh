#!/bin/bash
#
# 0x19e Networks
# Robert W. Baumgartner [rwb@0x19e.net]
#
# script for starting x11vnc on the current display
# uses the GDM login cookie to connect to X server
#
# note: requires a password be configured and stored
# the normal password file is usually ~/.vnc/passwd
# to configure a password, run:
#   `x11vnc -storepasswd`

hash x11vnc 2>/dev/null || { echo >&2 "You need to install x11vnc. Aborting."; exit 1; }

# . $(dirname $0)/helpers/log4bash.sh
# /run/user/122/gdm/Xauthority

CURRENT_UID=$(id -u $USER)
if [[ $CURRENT_UID == 0 ]]; then
  logger -p syslog.warn "WARNING: x11vnc found UID==0; forcing gdm UID"
  echo >&2 "WARNING: x11vnc found UID==0; forcing gdm UID"
  CURRENT_UID=$(id -u gdm)
fi

AUTH_COOKIE="/run/user/$CURRENT_UID/gdm/Xauthority"
LOG_FILE="/tmp/x11vnc-$USER.log"
# LOG_FILE="/home/$USER/x11vnc.log"

logger -p syslog.info "Starting x11vnc for user $USER (uid $CURRENT_UID) ..."
logger -p syslog.info "Logging to $LOG_FILE"

# check if x11vnc is already running
VNC_PID=$(ps -ef | grep "[x]11vnc" | grep $CURRENT_UID | awk '{ print $2}')
if [[ ! -z "$VNC_PID" ]]; then
  logger -p syslog.warn "ERROR: x11vnc appears to be running already for UID $CURRENT_UID."
  echo >&2 "ERROR: x11vnc appears to be running already for UID $CURRENT_UID."
  exit 1
fi

DISP_ARG="-display $DISPLAY"
if [[ -z "$DISPLAY" ]]; then
  logget -p syslog.info "WARNING: x11vnc could not detect display; using -find instead"
  echo >&2 "WARNING: x11vnc could not detect display; using -find instead"
  DISP_ARG="-find"
fi

if [[ ! -e "$AUTH_COOKIE" ]]; then
  logger -p syslog.error "ERROR: Could not find auth file."
  echo >&2 "ERROR: Could not find auth file."
  exit 2
fi

PW_OPT=""
if [[ -e /etc/x11vnc.pass ]]; then
  PW_OPT="-rfbauth /etc/x11vnc.pass"
fi

# note: use -logappend for persistent logging
x11vnc -auth $AUTH_COOKIE \
       $DISP_ARG \
       -logfile $LOG_FILE \
       -usepw $PW_OPT \
       -forever \
       -noxdamage > /dev/null 2>&1 &

VNC_PID=$(ps -ef | grep "[x]11vnc" | grep $CURRENT_UID | awk '{ print $2}')
if [[ -z "$VNC_PID" ]]; then
  logger -p syslog.error "ERROR: x11vnc failed to start."
  echo >&2 "ERROR: x11vnc failed to start."
  exit 3
fi

# give the socket a moment to bind
sleep 1

# get the port number
PORT=$(lsof -nPi | grep "IPv4" | grep "$VNC_PID" | awk '{print $9}' | awk -F":" '{print $2}')

# check to make sure value is a valid port
re='^[0-9]+$'
if ! [[ $PORT =~ $re ]] ; then
  logger -p syslog.error "ERROR: '$PORT' is not a valid port number"
  echo >&2 "ERROR: '$PORT' is not a valid port number"
  exit 4
fi

logger -p syslog.info "x11vnc started on display $DISPLAY; listening on 127.0.0.1:$PORT"
echo "x11vnc started on display $DISPLAY; listening on 127.0.0.1:$PORT"

exit 0
