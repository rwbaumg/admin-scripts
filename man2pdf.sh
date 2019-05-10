#!/bin/bash
# creates a pdf of a man page

hash ps2pdf 2>/dev/null || { echo >&2 "You need to install ghostscript. Aborting."; exit 1; }

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

    Generates a PDF from the specified manual page.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     page                  The manual page to generate a PDF from.

    OPTIONS

     -o, --output <value>  The path to save the output PDF to.
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
    if echo "$arg" | grep -qE '^-'; then
      usage "Null argument supplied for option $arg"
    fi
  fi

  if echo "$argv" | grep -qE '^-'; then
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

VERBOSITY=0
MAN_NAME=""
FORCE="false"

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -o|--output)
      test_arg "$1" "$2"
      shift
      OUTPUT=$(readlink -m "$1")
      shift
    ;;
    -f|--force)
      FORCE="true"
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      test_arg "$1"
      MAN_NAME="$1"
      shift
    ;;
  esac
done

if [ -z "$MAN_NAME" ]; then
  usage "No manual specified."
fi

if ! man "$MAN_NAME" > /dev/null 2>&1; then
  usage "No manual found for $MAN_NAME"
fi

if [ -z "$OUTPUT" ]; then
  # no output file specified, auto-name it
  if [ $VERBOSITY -gt 0 ]; then
    echo >&2 "INFO: No output file specified, using page name..."
  fi

  OUTPUT="$MAN_NAME.pdf"
fi

if [ -d "$OUTPUT" ]; then
  # a directory was specified for output; append a filename
  if [ $VERBOSITY -gt 0 ]; then
    echo >&2 "INFO: A directory was specified; appending file name..."
  fi

  OUTPUT="$OUTPUT/$MAN_NAME.pdf"
fi

if [ ! "$FORCE" = "true" ]; then
  test_path_arg "$OUTPUT"
fi

if [ $VERBOSITY -gt 1 ]; then
  echo MANUAL NAME = "${MAN_NAME}"
  echo OUTPUT FILE = "${OUTPUT}"
  echo VERBOSITY   = "${VERBOSITY}"
fi

if [ $VERBOSITY -gt 0 ]; then
  echo "Generating PDF for $MAN_NAME manual..."
fi

man -t "$MAN_NAME" | ps2pdf - "$OUTPUT"

if [ $VERBOSITY -gt 0 ]; then
  echo "PDF saved to $OUTPUT"
fi

exit_script 0
