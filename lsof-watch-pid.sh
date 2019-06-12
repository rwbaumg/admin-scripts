#!/bin/bash
# monitor open files on the specified pid

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
    if [ "$exit_code" -eq 0 ]; then
      echo "INFO: $*"
    else
      echo "ERROR: $*" 1>&2
    fi
  fi

  # Print 'aborting' string if exit code is not 0
  [ "$exit_code" -ne 0 ] && echo "Aborting script..."

  exit "$exit_code"
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename "$0")|" << EOF
    USAGE

    This script watches a process and displayed used files using lsof.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     pid                       The process ID to intercept.

    OPTIONS

     -n, --interval <value>    The interval between scanning for differences.

     -v, --verbose             Make the script more verbose.
     -h, --help                Prints this usage.

EOF

    exit_script "$@"
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

test_number()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  re='^[0-9]+$'
  if ! [[ "$argv" =~ $re ]] ; then
    usage "Argument must be numeric"
  fi
}

test_pid()
{
  # test pid argument
  local arg="$1"

  test_arg "$arg"

  if ! ps -p "$arg" > /dev/null; then
    usage "Specified PID not found."
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
INTERVAL=10

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -v|--verbose)
      ((VERBOSITY++))
      check_verbose
      shift
    ;;
    -n|--interval)
      test_number "$1" "$2"
      shift
      INTERVAL="$1"
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

check_root

watch -n $INTERVAL --differences lsof -p $PID

exit_script 0
