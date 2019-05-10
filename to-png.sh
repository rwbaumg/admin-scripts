#!/bin/bash
# converts piped input to a PNG image
# rwb[at]0x19e[dot]net

# ifconfig | convert label:@- ip.png

exit_script()
{
  # Default exit code is 1
  local exit_code=1
  local re var

  re='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'
  if echo "$1" | grep -q "$re"; then
    exit_code=$1
    shift
  fi

  re='[[:alnum:]]'
  if echo "$@" | grep -iq "$re"; then
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

    This script converts piped input text to a PNG image.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS

     -o, --output <value>  The path to save the output image to.
     -f, --force           Overwrite output file if it exists.

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
    if echo "$arg" | grep -q '^-'; then
      usage "Null argument supplied for option $arg"
    fi
  fi

  if echo "$argv" | grep -q '^-'; then
    usage "Argument for option $arg cannot start with '-'"
  fi
}

test_path_arg()
{
  # test directory argument
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  if [ -f "$argv" ]; then
    usage "Specified output file already exists."
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

OUTPUT="out.png"
FORCE="false"

# process arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -o|--output)
      test_arg "$1" "$2"
      shift
      OUTPUT="$1"
      shift
    ;;
    -f|--force)
      FORCE="true"
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
      # unknown argument
      usage "Unknown argument passed to script."
      shift
    ;;
  esac
done

if [ ! "$FORCE" = "true" ]; then
  test_path_arg "$OUTPUT"
fi

INPUT=$(cat)

echo -e "$INPUT" | convert label:@- $OUTPUT

exit_script 0
