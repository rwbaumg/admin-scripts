#!/bin/bash
# creates a secure tunnel to a domain's vnc port using stunnel
# [0x19e Networks] rwb@0x19e.net

RAND_FILE="/dev/urandom"
LOG_DIR="/var/log/stunnel4"
DEBUG_LEVEL=5
CIPHER_SUITE="ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!LOW:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SH"
USER="stunnel4"
GROUP="stunnel4"
CERT="/etc/ssl/private/stunnel.pem"
FIPS="no"

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
VNC_PORT=$(lsof -nPi | grep "LISTEN" | grep "$QEMU_PID" | awk '{print $9}' | awk -F":" '{print $2}')
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
PID_FILE="/tmp/stunnel_$VNC_PORT.pid"
LOG_FILE="$LOG_DIR/stunnel_$VNC_PORT.log"
CONF_FILE="/tmp/stunnel_$VNC_PORT.conf"

# check if $pidfile exists
if [ -e $PID_FILE ]; then
  pid=$(cat $PID_FILE)
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
FWD_NOTE=$(echo "local port $LISTEN_PORT -> 127.0.0.1:$VNC_PORT")

echo "forwarding $FWD_NOTE ..."

TUNNEL_CONF=$(sed -e "s|NAME|$DOMAIN_NAME|" \
                  -e "s|NOTE|$FWD_NOTE|" \
                  -e "s|CERT|$CERT|" \
                  -e "s|FIPS|$FIPS|" \
                  -e "s|CIPHERS|$CIPHER_SUITE|" \
                  -e "s|USER|$USER|" \
                  -e "s|GROUP|$GROUP|" \
                  -e "s|DEBUG_LEVEL|$DEBUG_LEVEL|" \
                  -e "s|RAND_FILE|$RAND_FILE|" \
                  -e "s|LOGFILE|$LOG_FILE|" \
                  -e "s|PID_FILE|$PID_FILE|" \
                  -e "s|LISTEN_PORT|$LISTEN_PORT|" \
                  -e "s|VNC_PORT|$VNC_PORT|" <<"EOF"
; stunnel4 config: NOTE
setuid = USER
setgid = GROUP
output = LOGFILE
pid = PID_FILE
RNDfile = RAND_FILE
fips = FIPS
ciphers = CIPHERS
debug = DEBUG_LEVEL
options = -NO_SSLv2
options = -NO_SSLv3
options = SINGLE_ECDH_USE
options = SINGLE_DH_USE

[NAME]
;client = yes
accept = LISTEN_PORT
connect = 127.0.0.1:VNC_PORT
cert = CERT
;verify = 0
;verify = 2
;CApath = @sysconfdir/ssl/certs
;OCSPaia = yes
EOF
)

echo -e "$TUNNEL_CONF" > $CONF_FILE
stunnel "$CONF_FILE"

exit 0

echo stunnel -options -D $DEBUG_LEVEL \
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
