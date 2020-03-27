#!/bin/bash
# Peform a binary diff of two files using hexdump

hash diff 2>/dev/null || { echo >&2 "You need to install diff (diffutils). Aborting."; exit 1; }
hash hexdump 2>/dev/null || { echo >&2 "You need to install hexdump (bsdmainutils). Aborting."; exit 1; }

export HEXDUMP_ARGS="-v -C"
export DIFFCMD_ARGS="-u"

function version_gt() { test "$(printf '%s\n' "$@" | sort -bt. -k1,1 -k2,2n -k3,3n -k4,4n -k5,5n | head -n 1)" != "$1"; }
function enable_diff_color() {
  DIFF_VERSION=$(diff --version | grep -Po '(?<=diff\s\(GNU\sdiffutils\)\s)[0-9\.]+$' | head -n1)
  if version_gt "${DIFF_VERSION}" "3.3"; then
    export DIFFCMD_ARGS="${DIFFCMD_ARGS} --color"
  fi
}

# uncomment to enable colored diffs where supported (version >= 3.4)
enable_diff_color

FILE1="$1"
FILE2="$2"

if [ -z "${FILE1}" ] || [ -z "${FILE2}" ]; then
  echo >&2 "Usage: $0 <file1> <file2>"
  exit 1
fi
if [ ! -e "${FILE1}" ]; then
  echo >&2 "ERROR: File '$FILE1' does not exist."
  exit 1
fi
if [ ! -e "${FILE2}" ]; then
  echo >&2 "ERROR: File '$FILE2' does not exist."
  exit 1
fi

# perform the actual diff
function perform_diff() {
  diff_cmd="diff ${DIFFCMD_ARGS}"
  hexdump_cmd="hexdump ${HEXDUMP_ARGS}"
  if ! ${diff_cmd} <(${hexdump_cmd} "${FILE1}") <(${hexdump_cmd} "${FILE2}"); then
    return 1
  fi
  return 0
}

if ! output=$(perform_diff); then
  if hash colordiff 2>/dev/null && ! echo "${DIFFCMD_ARGS}" | grep "\-\-color"; then
    echo "${output}" | colordiff
  else
    echo "${output}"
  fi
  exit 1
fi

echo "Files are identical."
exit 0
