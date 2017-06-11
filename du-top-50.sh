#!/bin/bash
# find large files

TOP_50_MSG="top 50 by size"
INPUT_PATH="."

if [ -n "$1" ]; then
  INPUT_PATH=$(readlink -m "$@")
  echo "$TOP_50_MSG: $INPUT_PATH"
else
  INPUT_PATH=$(readlink -m "$INPUT_PATH")
  echo "$TOP_50_MSG"
fi

trap cleanup EXIT INT TERM
cleanup() {
  kill $SCRIPT_PID
  exit $?
}

run_spinner()
{
  local msg="$1"
  local delay=0.5
  local i=1;
  local SP='\|/-';
  while [ "$SPIN" == "true" ]
  do
    printf "\b\r[${SP:i++%${#SP}:1}] $msg"
    sleep $delay;
  done
}

start_spinner()
{
  local arg="$1"

  SPIN="true"
  run_spinner "$1" &
  SCRIPT_PID=$!
}

stop_spinner()
{
  SPIN="false"

  # clear current line of any text
  echo -ne "\r%\033[0K\r"
}

start_spinner "Calculating directory sizes ..."

if [ "$INPUT_PATH" != "/" ]; then
  INPUT_PATH=${INPUT_PATH}"/"
fi

OUTPUT=$(du -hsx "${INPUT_PATH}"* 2>/dev/null \
           | sort -rh \
           | head -50)

stop_spinner

echo "$OUTPUT"

exit 0
