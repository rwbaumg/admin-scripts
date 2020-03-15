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
#hash netstat 2>/dev/null || { echo >&2 "You need to install net-tools. Aborting."; exit 1; }

# . $(dirname $0)/helpers/log4bash.sh
# /run/user/122/gdm/Xauthority

# How long to wait for vnc server to start
SLEEP_SEC=3

HAS_NETCAT="false"
if hash netstat 2>/dev/null; then
  HAS_NETCAT="true"
fi

DEBUG=0
CURRENT_UID=$(id -u "$USER")
if [[ $CURRENT_UID == 0 ]]; then
  if ! GDM_UID=$(id -u gdm); then
    logger -p syslog.error "ERROR: Failed to determine gdm UID."
    echo >&2 "ERROR: Failed to determine gdm UID."
    exit 1
  fi
  logger -p syslog.warn "WARNING: x11vnc found UID==0; forcing gdm UID ${GDM_UID} ..."
  echo >&2 "WARNING: x11vnc found UID==0; forcing gdm UID ${GDM_UID} ..."
  CURRENT_UID="${GDM_UID}"
fi

CURRENT_USER="$USER"
if [[ -z "$CURRENT_USER" ]]; then
  if ! CURRENT_USER=$(getent passwd "$CURRENT_UID" | awk -F: '{ print $1 }'); then
    logger -p syslog.warn "WARNING: Failed to resolve username for UID ${CURRENT_UID}."
    echo >&2 "WARNING: Failed to resolve username for UID ${CURRENT_UID}."
  fi
fi
if [[ -z "$CURRENT_USER" ]]; then
  logger -p syslog.error "ERROR: x11vnc could not identify the user to run under."
  echo >&2 "ERROR: x11vnc could not identify the user to run under."
  exit 1
fi

AUTH_COOKIE="/run/user/$CURRENT_UID/gdm/Xauthority"
LOG_FILE="/tmp/x11vnc-$CURRENT_USER.log"
# LOG_FILE="/home/$CURRENT_USER/x11vnc.log"

logger -p syslog.info "Starting x11vnc for user $CURRENT_USER (uid $CURRENT_UID) ..."
logger -p syslog.info "Logging to $LOG_FILE"

echo "INFO: Starting x11vnc for user $CURRENT_USER (uid $CURRENT_UID) ..."
echo "INFO: Logging to $LOG_FILE"

# check if x11vnc is already running
VNC_PID=$(pgrep -f "^[x]11vnc" --euid "$CURRENT_UID")
if [[ -n "$VNC_PID" ]]; then
  logger -p syslog.error "ERROR: x11vnc appears to be running already for UID $CURRENT_UID (pid $VNC_PID)."
  echo >&2 "ERROR: x11vnc appears to be running already for UID $CURRENT_UID (pid $VNC_PID)."
  exit 1
fi

DISP_ARG="-display $DISPLAY"
if [[ -z "$DISPLAY" ]]; then
  logger -p syslog.warn "WARNING: x11vnc could not detect display; using -find instead"
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
  logger -p syslog.info "INFO: x11vnc using authentication file /etc/x11vnc.pass"
  echo >&2 "INFO: x11vnc using authentication file /etc/x11vnc.pass"
fi

# note: use -logappend for persistent logging
VNC_CMD="x11vnc -bg $DISP_ARG -usepw $PW_OPT"
${VNC_CMD} -auth "$AUTH_COOKIE" \
           -logfile "$LOG_FILE" \
           -forever \
           -noxdamage > /dev/null 2>&1 &

# give the socket a moment to bind
sleep ${SLEEP_SEC}

VNC_PID=$(pgrep -f "^[x]11vnc" --euid "$CURRENT_UID")
if [[ -z "$VNC_PID" ]]; then
  logger -p syslog.error "ERROR: x11vnc failed to start."
  echo >&2 "ERROR: x11vnc failed to start."
  exit 3
else
  logger -p syslog.info "INFO: Detected x11vnc running on pid $VNC_PID, waiting for socket..."
  echo >&2 "INFO: Detected x11vnc running on pid $VNC_PID, waiting for socket..."
fi

# get the port number
PORT=""
if [ "${HAS_NETCAT}" == "true" ]; then
  PORT=$(netstat -4 -an --tcp --program 2> /dev/null | grep "$VNC_PID" | awk '{print $4}' | awk -F":" '{print $2}' | head -n1)
else
  PORT=$(lsof -nPi | grep "IPv4" | grep "$VNC_PID" | awk '{print $9}' | awk -F":" '{print $2}' | head -n1)
fi

# DEBUG: log all ports visible at this point in the script
if [[ "$DEBUG" == 1 ]]; then
  TEST=$(netstat -4 -an --tcp --program)
  logger -p syslog.error "x11vnc is able to see the following ports: $TEST"
fi

# check if we were able to find the listen port, and if so, validate it
re='^[0-9]+$'
if ! [[ $PORT =~ $re ]] ; then
  if ! [[ -z $PORT ]]; then
    logger -p syslog.error "ERROR: '$PORT' is not a valid x11vnc port number."
    echo >&2 "ERROR: '$PORT' is not a valid x11vnc port number."
    exit 4
  else
    # port is null but x11vnc is running
    PORT="?"
    logger -p syslog.warn "WARNING: Unable to determine which port x11vnc is listening on."
    echo >&2 "WARNING: Unable to determine which port x11vnc is listening on."
  fi
fi

echo "INFO: Found open x11vnc socket on port ${PORT}/tcp"

display_string="display ${DISPLAY}"
if [ -z "${DISPLAY}" ]; then
  echo >&2 "WARNING: Unable to determine display."
  display_string="unknown display"
fi

logger -p syslog.info "x11vnc started on display $DISPLAY; listening on 127.0.0.1:$PORT"
echo "INFO: x11vnc started on $display_string; listening on 127.0.0.1:$PORT"

exit 0
