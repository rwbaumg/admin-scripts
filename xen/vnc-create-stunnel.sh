#!/bin/bash
# creates a secure tunnel to a domain's vnc port using stunnel
# [0x19e Networks] rwb@0x19e.net

PEM_FILE="/etc/ssl/private/athena-private.pem"
RAND_FILE="/dev/urandom"
LOG_FILE="/var/log/stunnel4/stunnel.log"
DEBUG_LEVEL=5
CIPHER_SUITE="ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!LOW:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SH"
USER="stunnel4"
GROUP="stunnel4"

# check if stunnel is installed
hash stunnel 2>/dev/null || { echo >&2 "You need to install stunnel. Aborting."; exit 1; }

# check if superuser
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# check arguments
if [[ -z "$1" ]]; then
  echo "Usage: $0 <domain name>" >&2
  exit 1
fi

# resolve script directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
# echo >&2 "script directory resolved to $DIR"

# validate domain
DOMAIN_NAME="$1"
QEMU_PID=$(ps -ef | grep "qemu" | grep "name $DOMAIN_NAME" | awk '{ print $2}')
if [[ -z "$QEMU_PID" ]]; then
  echo >&2 "ERROR: Failed to find qemu pid for '$DOMAIN_NAME'"
  exit 1
fi

# get the vnc port
VNC_PORT=$(lsof -nPi | grep "$QEMU_PID" | awk '{print $9}' | awk -F":" '{print $2}')
if [ "$VNC_PORT" = "" ]; then
  echo >&2 "ERROR: Failed to find VNC port for '$DOMAIN_NAME'"
  exit 1
fi
re='^[0-9]+$'
if ! [[ $VNC_PORT =~ $re ]] ; then
  echo >&2 "ERROR: Failed to find VNC port for '$DOMAIN_NAME': '$VNC_PORT' is not a valid int"
  exit 1
fi
echo "vnc port for $DOMAIN_NAME: $VNC_PORT"

# configure port and pid file
LISTEN_PORT=2$VNC_PORT
PID_FILE="/tmp/stunnel3_$VNC_PORT.pid"

# check if $pidfile exists
if [ -e $PID_FILE ]; then
  pid=`cat $PID_FILE`
  # check if pid is running
  if ( kill -0 $pid > /dev/null 2>&1; ); then
    echo "stunnel already running on pid $pid"
    exit 1
  else
    echo >&2 "pid file exists but process not running, deleting stale pid file..."
    rm -f $PID_FILE
  fi
fi

# forward
echo "forwarding $LISTEN_PORT -> 127.0.0.1:$VNC_PORT ..."

stunnel -D $DEBUG_LEVEL \
        -s "$USER" \
        -g "$GROUP" \
        -C "$CIPHER_SUITE" \
        -R "$RAND_FILE" \
        -o "$LOG_FILE" \
        -P "$PID_FILE" \
        -p "$PEM_FILE" \
        -d $LISTEN_PORT \
        -r $VNC_PORT

exit 0
