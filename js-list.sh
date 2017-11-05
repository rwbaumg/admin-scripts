#!/bin/bash
# dumps joystick info

JS_PATH="/dev/input/js*"

if ls $JS_PATH 1> /dev/null 2>&1; then
  for js in $JS_PATH; do
    echo $js
    udevadm info $js
  done
else
  echo "No joysticks detected."
fi

echo
echo "DKMS Modules:"
dkms status

exit 0
