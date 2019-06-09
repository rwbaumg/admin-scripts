#!/bin/bash
# find large files

TOP_20_MSG="top 20 by size"
INPUT_PATH="."

if [ -z "${NO_SPINNER}" ]; then
  NO_SPINNER=0
fi

if [ -n "$1" ]; then
  if [ ! -d "$@" ]; then
    echo >&2 "usage: $0 [directory]"
    exit 1
  fi
  INPUT_PATH=$(readlink -m "$@")
  echo "$TOP_20_MSG: $INPUT_PATH"
else
  INPUT_PATH=$(readlink -m "$INPUT_PATH")
  echo "$TOP_20_MSG"
fi

trap cleanup EXIT INT TERM
cleanup() {
  if [ -n "$SCRIPT_PID" ]; then
    kill $SCRIPT_PID
  fi
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


if [ "$NO_SPINNER" -eq 0 ]; then
  start_spinner "Calculating directory sizes ..."
fi

INPUT_PATH_ESCAPED=""
if [ "$INPUT_PATH" != "/" ]; then
  INPUT_PATH=${INPUT_PATH}"/"
  INPUT_PATH_ESCAPED=$(readlink -m "${INPUT_PATH}" | sed -e 's/\//\\\//g' -e 's/\./\\\./g')
fi

pushd "${INPUT_PATH}" > /dev/null 2>&1

OUTPUT=$((du -shx ./.[^.]* 2>/dev/null ; du -shx ./[^.]* 2>/dev/null) \
           | sed "s/\.\//${INPUT_PATH_ESCAPED}\//g" \
           | LC_ALL=C sort -k2 | sort -rh \
           | head -20)

popd > /dev/null 2>&1

if [ "$NO_SPINNER" -eq 0 ]; then
  stop_spinner
fi

echo "$OUTPUT"

exit 0
