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

AUTH_COOKIE="/run/user/$UID/gdm/Xauthority"
LOG_FILE="$HOME/x11vnc.log"

# check if x11vnc is already running
VNC_PID=$(pidof -s "x11vnc")
if [[ ! -z "$VNC_PID" ]]; then
  echo >&2 "ERROR: x11vnc appears to be running already."
  exit 1
fi

if [[ ! -e "/run/user/$UID/gdm/Xauthority" ]]; then
  echo >&2 "ERROR: Could not find auth file."
  exit 2
fi

x11vnc -auth $AUTH_COOKIE \
       -display $DISPLAY \
       -logappend $LOG_FILE \
       -usepw \
       -forever \
       -noxdamage > /dev/null 2>&1 &

VNC_PID=$(pidof -s "x11vnc")
if [[ -z "$VNC_PID" ]]; then
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
  echo >&2 "ERROR: '$PORT' is not a valid port number"
  exit 4
fi

echo "x11vnc started on display $DISPLAY; listening on 127.0.0.1:$PORT"

exit 0
