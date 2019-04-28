#!/bin/bash
# Runs an executable using the CWD for shared libraries

if [[ -z "$@" ]]; then
  echo >&2 "Usage: $0 <command>"
  exit 1
fi

CWD=$(pwd)
echo "LD_LIBRARY_PATH=${PWD}"

LD_LIBRARY_PATH=${PWD} $@

exit $?
