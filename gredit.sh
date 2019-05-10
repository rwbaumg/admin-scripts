#!/bin/bash
# [ 0x19e Networks ]
#  http://0x19e.net
# Author: Robert W. Baumgartner <rwb@0x19e.net>
#
# Allows editing a range of files by locating similar lines.
# Two grep patterns are used to locate lines: the first allows narrowing the context to a block of
# text that contains the actual target line. This is done using a regular expression and an integer
# defining how many lines surrounding each match to include when the next search is performed.
# The final search simply greps for a given target string, which must be an exact match.
# Every match is then processed to construct edit commands.

EDIT_COMMAND="editor"
DEFAULT_CTX_LINES=20

GREP_EXT_OPTS="-r"
GREP_LOCATION="*"

CONTEXT_REGEX=""
TARGET_STRING=""
CONTEXT_LINES=${DEFAULT_CTX_LINES}

#CONTEXT_REGEX="EOF"
#CONTEXT_REGEX="^[\s[A-Za-z0-9\-\_]+ocsp[A-Za-z0-9\-\_]+\s]$"
#TARGET_STRING="sed\s\-e"
#TARGET_STRING="authorityInfoAccess"

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
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename $0)|" << "EOF"
    USAGE

    Edit a configuration settings across multiple files in a directory using grep.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

      path                  The location to search within.

    OPTIONS

     -c, --context <regex>  A RegEx to locate lines close to the desired target.
     -t, --target <expr>    An expression identifying the target lines to process.
     -s, --search <lines>   The number of lines around context matches to search within.

     -v, --verbose          Make the script more verbose.
     -h, --help             Prints this usage.

    EXAMPLES

      - To search and edit AIA OCSP settings within an OpenSSL configuration:
        `~/gredit.sh -c '^[\s[A-Za-z0-9\-\_]+ocsp[A-Za-z0-9\-\_]+\s]$' -t 'authorityInfoAccess' -s 20 ./ssl-config/`

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

  if [ ! -e "$argv" ]; then
    usage "Specified directory does not exist: $argv"
  fi
}

test_number_arg()
{
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  re='^[0-9]+$'
  if ! [[ $argv =~ $re ]] ; then
    usage "Option for argument $arg must be numeric."
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

[ $# -gt 0 ] || usage

i=1
argc=$#
TARGET_DIR=""

# process arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -c|--context)
      test_arg "$1" "$2"
      shift
      CONTEXT_REGEX="$1"
      shift
    ;;
    -t|--target)
      test_arg "$1" "$2"
      shift
      TARGET_STRING="$1"
      shift
    ;;
    -s|--search)
      test_number_arg "$1" "$2"
      shift
      CONTEXT_LINES="$1"
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      check_verbose
      i=$((i+1))
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      if [ ! -z "${TARGET_DIR}" ]; then
        usage "Cannot specify multiple search locations."
      fi
      test_path_arg "$1"
      TARGET_DIR="$1"
      shift
    ;;
  esac
done

GREP_CTX_OPTS="-r -P"
if [ -z "${TARGET_STRING}" ]; then
  usage "Must specify a target string to search for."
fi
if [ -z "${CONTEXT_REGEX}" ]; then
  if [ ${CONTEXT_LINES} -eq ${DEFAULT_CTX_LINES} ]; then
    CONTEXT_LINES=1
  fi
  GREP_CTX_OPTS=""
  CONTEXT_REGEX="${TARGET_STRING}"
fi

if [ -z "${TARGET_DIR}" ]; then
  TARGET_DIR="$(realpath .)"
fi

pushd "${TARGET_DIR}" > /dev/null 2>&1

IFS=$'\n'; for l in $(grep ${GREP_EXT_OPTS} -n ${GREP_CTX_OPTS} ${CONTEXT_REGEX} ${GREP_LOCATION} -A${CONTEXT_LINES} \
  | grep ${TARGET_STRING} | grep -v -P "(\-|\:)[0-9]+(\-|\:)([\s]+)?\#" \
  | sed -r "s/\-([0-9]+)\-${TARGET_STRING}/\:\1\:${TARGET_STRING}/" \
  | awk -F: '{ printf "+%s %s\n", $2, $1 }'); do bash -c "${EDIT_COMMAND} ${l}"; done

popd > /dev/null 2>&1

exit $?
