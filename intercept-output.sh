#!/bin/bash
# intercept stdout/stderr of the specified process
# rwb[at]0x19e[dot]net

hash strace 2>/dev/null || { echo >&2 "You need to install strace. Aborting."; exit 1; }

exit_script()
{
  # Default exit code is 1
  local exit_code=1
  local re

  re='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'
  if echo "$1" | grep -qE "$re"; then
    exit_code=$1
    shift
  fi

  re='[[:alnum:]]'
  if echo "$@" | grep -iqE "$re"; then
    if [ $exit_code -eq 0 ]; then
      echo "INFO: $@"
    else
      echo "ERROR: $@" 1>&2
    fi
  fi

  # Print 'aborting' string if exit code is not 0
  [ $exit_code -ne 0 ] && echo "Aborting script..."

  exit $exit_code
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename $0)|" << EOF
    USAGE

    This script intercepts stdout / stderr of a running process.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     pid                   The process ID to intercept.

    OPTIONS

     -v, --verbose         Make the script more verbose.
     -h, --help            Prints this usage.

EOF

    exit_script $@
}

test_arg()
{
  # Used to validate user input
  local arg="$1"
  local argv="$2"

  if [ -z "$argv" ]; then
    if echo "$arg" | grep -qE '^-'; then
      usage "Null argument supplied for option $arg"
    fi
  fi

  if echo "$argv" | grep -qE '^-'; then
    usage "Argument for option $arg cannot start with '-'"
  fi
}

test_pid()
{
  # test pid argument
  local arg="$1"

  test_arg $arg

  if ! ps -p $arg > /dev/null; then
    usage "Specified PID not found."
  fi
}

test_user_arg()
{
  # test user argument
  local arg="$1"
  local argv="$2"

  test_arg $arg $argv

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  if ! getent passwd "$argv" > /dev/null 2>&1; then
    usage "Specified user does not exist."
  fi
}

test_group_arg()
{
  # test group argument
  local arg="$1"
  local argv="$2"

  test_arg $arg $argv

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  if ! getent group "$argv" > /dev/null 2>&1; then
    usage "Specified group does not exist."
  fi
}

check_root() {
  # check if superuser
  if [[ $EUID -ne 0 ]]; then
    exit_script 1 "This script must be run as root."
  fi
}

VERBOSE=""
VERBOSITY=0

check_verbose()
{
  if [ $VERBOSITY -gt 1 ]; then
    VERBOSE="-v"
  fi
}

PID=""

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -v|--verbose)
      ((VERBOSITY++))
      check_verbose
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      test_pid "$1"
      PID="$1"
      shift
    ;;
  esac
done

# print options
if [ $VERBOSITY -gt 1 ]; then
  echo PROCESS ID = "${PID}"
fi

if [ $VERBOSITY -gt 0 ]; then
  echo "Intercepting $PID ..."
fi

strace -ff -e trace=write -e write=1,2 -p $PID

# more user-friendly?
#strace -ff -e write=1,2 -s 1024 -p PID  2>&1 \
#| grep "^ |" \
#| cut -c11-60 \
#| sed -e 's/ //g' \
#| xxd -r -p

# to get ALL output:
#strace -e write=1,2 -p $PID 2>&1 \
#| sed -un "/^ |/p" \
#| sed -ue "s/^.\{9\}\(.\{50\}\).\+/\1/g" -e 's/ //g' \
#| xxd -r -p

exit_script 0
