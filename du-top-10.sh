#!/bin/bash
# find large files

TOP_10_MSG="top 10 by size"
INPUT_PATH="."

if [ -n "$1" ]; then
  INPUT_PATH=$(readlink -m "$@")
  echo "$TOP_10_MSG: $INPUT_PATH"
else
  INPUT_PATH=$(readlink -m "$INPUT_PATH")
  echo "$TOP_10_MSG"
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

pushd "${INPUT_PATH}" > /dev/null 2>&1

OUTPUT=$((du -shx ./.[^.]* 2>/dev/null ; du -shx ./[^.]* 2>/dev/null) \
           | LC_ALL=C sort -k2 | sort -rh \
           | head -10)

popd > /dev/null 2>&1

stop_spinner

echo "$OUTPUT"

exit 0
