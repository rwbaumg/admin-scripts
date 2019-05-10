#!/bin/bash
# find broken symlinks

exit_script()
{
  # Default exit code is 1
  local exit_code=1
  local re var

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

    This script scans for broken symlinks.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     directory             The staring directory to search from.

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

test_path()
{
  # test directory argument
  local arg="$1"

  test_arg $arg

  if [ ! -d "$arg" ]; then
    usage "Specified directory does not exist."
  fi
}

SEARCH_DIR=""
VERBOSITY=0

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      shift
    ;;
    *)
      test_path "$1"
      SEARCH_DIR=$(readlink -m "$1")
      shift
    ;;
  esac
done

if [ $VERBOSITY -gt 0 ]; then
  echo "Scanning for broken symlinks in $SEARCH_DIR ..."
fi

find -L "$SEARCH_DIR" -type l

if [ $VERBOSITY -gt 0 ]; then
  echo "Done. Results are displayed above."
fi

exit_script 0
