#!/bin/bash
# renames one or more files
# todo: add --dry-run support

hash sed 2>/dev/null || { echo >&2 "You need to install sed. Aborting."; exit 1; }

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

    This script renames a range of files in one or more folders.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     paths ...             A list of directories containing files
                           that should be renamed.

    OPTIONS
     -c, --criteria        The staring directory to search from.
     -p, --previous        A regular expression of the string to
                           be replaced in the located file's names.
     -n, --new             The new value to use.

     -v, --verbose         Make the script more verbose.
     -h, --help            Prints this usage.

    EOF

    exit_script $@
}

VERBOSE=""
VERBOSITY=0

check_verbose()
{
  if [ $VERBOSITY -gt 1 ]; then
    VERBOSE="-v"
  fi
}

# process arguments
#echo num params=$#
#saved=("$@")

[ $# -gt 2 ] || usage

i=1
argc=$#

while [ $# -gt 0 ]; do
  case "$1" in
    -v|--verbose)
      ((VERBOSITY++))
      check_verbose
      i=$((i+1))
      shift
    ;;
    -l|--location)
      shift
      location=$1
      i=$((i+1))
      shift
    ;;
    -c|--criteria)
      shift
      criteria=$1
      i=$((i+1))
      shift
    ;;
    -p|--previous)
      shift
      re_match=$1
      i=$((i+1))
      shift
    ;;
    -n|--new)
      shift
      replace=$1
      i=$((i+1))
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      shift
    ;;
  esac
done

# for testing
#echo "set -- $saved-$i"
#set -- $saved
#echo num params=$#
#for ((i=$#; i>0; i--)); do
#  echo "Parameter $i is ${!i}"
#done

if [ -z "$criteria" ]; then
  usage "No criteria was specified."
fi
if [ -z "$re_match" ]; then
  usage "No expression for the previous string was supplied."
fi
if [ -z "$replace" ]; then
  usage "Need to specify a string to replace with."
fi

if [ -z "$location" ]; then
  location="."
fi

echo "Renaming files matching '*$criteria*' under '$location' ..."

# note: was using $* before argument parsing implementation changed
find $location -type f -name "*$criteria*" -print0 | while IFS= read -r -d '' file; do
  src=$file
  tgt=$(echo $file | sed -e "s/$re_match/$replace/")
  if [ "$src" != "$tgt" ]; then
     mv $VERBOSE "$src" "$tgt"
  fi
done

exit_script 0
