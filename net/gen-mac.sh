#!/bin/bash
# Generate a new MAC address given a hostname
# rwb[at]0x19e[dot]net

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
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename $0)|" <<"    EOF"
    USAGE

    Generates either a random or deterministic MAC address.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     seed                  A seed which is used to genrate the new
                           MAC address. Something like a FQDN works
                           well, but any unique string is valid.

    OPTIONS

     -r, --random          Use /dev/urandom to seed generation.
     -s, --seed <value>    Specify the seed to use for generation.
     -p, --prefix <value>  Specify the single-byte prefix for the
                           generated address (must be even).
                           Default: \x88

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

test_prefix()
{
  # test prefix argument
  # note: first octet must be even according to spec
  local arg="$1"

  if [ -z "$arg" ]; then
    usage "Prefix cannot be null."
  fi

  re="^([0-9a-f][0-9a-f])$"
  if ! `echo "$1" | egrep -q "$re"`; then
    usage "Invalid prefix: $arg"
  fi

  value=$((16#$arg))
  if [ $((value % 2)) -ne 0 ]; then
    usage "Prefix must be even: $arg"
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

PREFIX="88"
FQDN=""
RNDSEED="false"

# process arguments
# [ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -p|--prefix)
      test_arg "$1" "$2"
      shift
      PREFIX="$1"
      shift
    ;;
    -s|--seed)
      if [[ ! -z "$SEED" ]]; then
        usage "Seed specified multiple times."
      fi
      test_arg "$1" "$2"
      shift
      SEED="$1"
      shift
    ;;
    -r|--random)
      RNDSEED="true"
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      check_verbose
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      if [[ ! -z "$SEED" ]]; then
        usage "Seed specified multiple times."
      fi
      test_arg "Seed" "$1"
      SEED="$1"
      shift
    ;;
  esac
done

test_prefix "$PREFIX"

if [ "$RNDSEED" = "true" ]; then
  # SEED=$(uuidgen)
  SEED=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
elif [ -z "$SEED" ]; then
  usage "Seed is null and random not specified."
fi

# note: first octet must be event according to spec
# the Xensource id is 00:16:3e
# the x19e id is 30:16:c6

if [ $VERBOSITY -gt 0 ]; then
  echo "Seed: $SEED"
fi

MACADDR=$(echo "$SEED"|sha1sum|sed "s/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/${PREFIX}:\1:\2:\3:\4:\5/")

echo $MACADDR

exit_script 0
