#!/bin/bash
# script to synchronize with a remote branch
# rwb[at]0x19e[dot]net

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }
hash sed 2>/dev/null || { echo >&2 "You need to install sed. Aborting."; exit 1; }
hash grep 2>/dev/null || { echo >&2 "You need to install grep. Aborting."; exit 1; }

# default remotes
SOURCE_REMOTE="origin"
SOURCE_BRANCH="master"

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
        echo
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

    Synchronize a local branch with a remote's, overwriting local changes.

    This script allows pulling a forced commit.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS

     -r, --remote <value>   The name of the remote to pull from. (default: origin)
     -b, --branch <value>   The name of the branch to synchronize. (default: master)

     --dry-run              Do everything except actually send the updates.

     -v, --verbose          Make the script more verbose.
     -h, --help             Prints this usage.
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

VERBOSITY=0
GIT_VERBOSE=""
GIT_DRY_RUN=""

check_verbose()
{
  if [ $VERBOSITY -gt 1 ]; then
    GIT_VERBOSE="-v"
  fi
}

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -b|--branch)
      test_arg "$1" "$2"
      shift
      SOURCE_BRANCH="$1"
      shift
    ;;
    -r|--remote)
      test_arg "$1" "$2"
      shift
      SOURCE_REMOTE="$1"
      shift
    ;;
    --dry-run)
      GIT_DRY_RUN="--dry-run"
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      check_verbose
      shift
    ;;
    -vv)
      ((VERBOSITY++))
      ((VERBOSITY++))
      check_verbose
      shift
    ;;
    -h|--help)
      usage
    ;;
    *)
      # unknown option
      shift
    ;;
  esac
done

if [ -z "$SOURCE_REMOTE" ]; then
  usage "No remote specified."
fi
if [ -z "$SOURCE_BRANCH" ]; then
  usage "No branch specified."
fi

# combine git flags
GIT_EXTRA_ARGS="$GIT_VERBOSE $GIT_DRY_RUN"

# print options
if [ $VERBOSITY -gt 1 ]; then
  echo ORIGIN REMOTE = "${SOURCE_REMOTE}"
  echo TARGET REMOTE = "${SOURCE_BRANCH}"
  echo GIT ARGUMENTS = "${GIT_EXTRA_ARGS}"
fi

# check that we're actually in a repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo >&2 "Current directory is not a git repository. Aborting."
  exit 1
fi

# check remotes
if ! git ls-remote $SOURCE_REMOTE > /dev/null 2>&1; then
  if [ "$GIT_FORCE" == "--force" ]; then
    echo >&2 "WARNING: Working copy doesn't have a source remote named '$SOURCE_REMOTE'."
  else
    echo >&2 "Working copy doesn't have a source remote named '$SOURCE_REMOTE'. Aborting."
    exit 1
  fi
fi

SOURCE_PATH="$SOURCE_REMOTE/$SOURCE_BRANCH"

if [ $VERBOSITY -gt 0 ]; then
  echo "Syncing branch $SOURCE_BRANCH with $SOURCE_PATH ..."
fi

if [ "$GIT_DRY_RUN" = "--dry-run" ]; then
  echo git checkout $SOURCE_BRANCH
  echo git fetch $GIT_EXTRA_ARGS --all
  echo git reset --hard $SOURCE_PATH
  echo git pull $GIT_EXTRA_ARGS $SOURCE_REMOTE $SOURCE_BRANCH
else
  git checkout $SOURCE_BRANCH
  git fetch $GIT_EXTRA_ARGS --all
  git reset --hard $SOURCE_PATH
  git pull $GIT_EXTRA_ARGS $SOURCE_REMOTE $SOURCE_BRANCH
fi

exit_script 0
