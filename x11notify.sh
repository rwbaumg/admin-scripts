#!/bin/bash
# X11 Notification Script
#
# The example below displays a reminder for the current user:
#   export $(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $LOGNAME gnome-session)/environ);
#   /usr/bin/notify-send -i appointment -c "im" "Example reminder" --icon=dialog-warning

if [ -z "$1" ]; then
  echo >&2 "Usage: $0 <message>"
  exit 1
fi

MESSAGE="$1"
CATEGORY="alerts"
URGENCY="normal"
ICON="dialog-information"

hash notify-send 2>/dev/null || { echo >&2 "You need to install libnotify-bin. Aborting."; exit 1; }

# Get required paths
NOTIFY_SEND=$(which notify-send)

# Get a list of active sessions
SESSIONS=$(w -hs | awk -v tty="$(cat /sys/class/tty/tty0/active)" '$2 == tty && $3 != "-" {print $1 FS $3}')

# Process each session
IFS=$'\n'
for SESSION in ${SESSIONS}; do
  USER=$(echo "${SESSION}" | awk '{print $1}')
  DISP=$(echo "${SESSION}" | awk '{print $2}')

  echo "Sending message to ${USER} on display ${DISP} ..."
  export DISPLAY=${DISP};
  export "$(grep -z DBUS_SESSION_BUS_ADDRESS "/proc/$(pgrep -u "${USER}" gnome-session)/environ")"
  ${NOTIFY_SEND} -u "${URGENCY}" -c "${CATEGORY}" "${MESSAGE}" -i "${ICON}"
done

exit 0
