#!/bin/bash
# scan a directory for expired or expiring ssl certificates

exit_script()
{
  # Default exit code is 1
  local exit_code=1
  local re var

  re='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'
  if echo "$1" | egrep -q "$re"; then
    exit_code=$1
    shift
  fi

  re='[[:alnum:]]'
  if echo "$@" | egrep -iq "$re"; then
    if [ $exit_code -eq 0 ]; then
      echo >&2 "INFO: $@"
    else
      echo "ERROR: $@" 1>&2
    fi
  fi

  # Print 'aborting' string if exit code is not 0
  [ $exit_code -ne 0 ] && echo >&2 "Aborting script..."

  exit $exit_code
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename $0)|" <<"    EOF"
    USAGE

    This script scans for expired certificates.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     directory             The staring directory to search from.

    OPTIONS

     -t, --time <sec>      Acceptable time-to-expiration (in seconds).
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
    if echo "$arg" | egrep -q '^-'; then
      usage "Null argument supplied for option $arg"
    fi
  fi

  if echo "$argv" | egrep -q '^-'; then
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

EXPIRE_TIME=0
SEARCH_DIR=""
VERBOSITY=0

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
    ;;
    -t|--time)
      test_arg "$1" "$2"
      shift
      EXPIRE_TIME=$1
      shift
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
  echo >&2 "Scanning for expired or expiring certificates in $SEARCH_DIR ..."
  if [ $EXPIRE_TIME -gt 0 ]; then
    echo >&2 "Time-to-expiration: $EXPIRE_TIME sec."
  fi
fi

found=0

find "$SEARCH_DIR" -not -empty -type f -name "*.crt" -print0 |
while IFS= read -r -d $'\0' cert; do
  if ! openssl x509 -noout -checkend $EXPIRE_TIME -in $cert;
  then
    let found+=1
    echo "$cert"
  fi
done

# TODO: Count not working
#if [ $VERBOSITY -gt 0 ]; then
#  echo >&2 "Found $found expired certificate(s)."
#fi

exit_script 0
