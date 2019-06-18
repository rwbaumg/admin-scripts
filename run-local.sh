#!/bin/bash
# Runs an executable using the CWD for shared libraries

if [[ -z "$@" ]]; then
  echo >&2 "Usage: $0 <command>"
  exit 1
fi

CWD=$(pwd)
CMD="LD_LIBRARY_PATH=${CWD} $*"

if [[ "$VERBOSE" =~ 1|true ]] || [[ "$VERBOSITY" -gt 0 ]]; then
  echo "LD_LIBRARY_PATH=${CWD}" >&2
fi

if ! bash -c "${CMD}"; then
  exit 1
fi

exit 0
