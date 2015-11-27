#!/bin/bash
# converts a git repository to be shared
# rwb[at]0x19e[dot]net

# default settings
GIT_USER="root"
GIT_GROUP="git"

FILE_MASK=664
DIR_MASK=775

VERBOSITY=0

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

pushd()
{
  command pushd "$@" > /dev/null
}

popd()
{
  if [ `dirs -p -v | wc -l` -gt 1 ]; then
    command popd "$@" > /dev/null
  fi
}

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

  # pop back to start directory
  popd

  exit $exit_code
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename $0)|" <<"    EOF"
    USAGE

    This script sets up a bare Git repository for shared usage.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     repository            The bare Git repository to make shared.

    OPTIONS

     -u, --user <value>    The user that should own the repository.
     -g, --group <value>   The group that should own the repository.

     --no-shared           Do not reconfigure repository (only permissions).
     --dry-run             Print commands without making any changes.

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

  # this is just a preliminary check since rev-parse doesn't work
  # until after we change directory to the supplied path. we'll
  # validate it's actually a repository later.
  if ! [ -d "$arg/objects" ] || ! [ -d "$arg/refs" ] || ! [ -d "$arg/info" ]; then
    usage "Specified directory does not appear to be a bare Git repository."
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

VERBOSE=""

check_verbose()
{
  if [ $VERBOSITY -gt 1 ]; then
    VERBOSE="-v"
  fi
}

GIT_DIR=""
DRY_RUN="false"
NO_SHARED="false"

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    -u|--user)
      test_user_arg "$1" "$2"
      shift
      GIT_USER="$1"
      shift
    ;;
    -g|--group)
      test_group_arg "$1" "$2"
      shift
      GIT_GROUP="$1"
      shift
    ;;
    --no-shared)
      NO_SHARED="true"
      shift
    ;;
    --dry-run)
      DRY_RUN="true"
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
      test_path "$1"
      GIT_DIR="$1"
      shift
    ;;
  esac
done

check_root() {
  # check if superuser
  if [[ $EUID -ne 0 ]]; then
    echo >&2 "This script must be run as root"
    exit_script 1
  fi
}

check_verbose

# perform final checks
test_path "$GIT_DIR"
test_user_arg "$GIT_USER"
test_group_arg "$GIT_GROUP"

# ensure the script is run as root, otherwise we may not have
# sufficient permissions to reconfigure the repository
if [ "$DRY_RUN" = "false" ]; then
  check_root
fi

pushd $GIT_DIR

if [ `git rev-parse --is-bare-repository` = "false" ]; then
  usage "Specified directory is not a bare Git repository: $GIT_DIR"
fi

# print options
if [ $VERBOSITY -gt 1 ]; then
  echo GIT REPOSITORY   = "${GIT_DIR}"
  echo DESIRED OWNER    = "${GIT_USER}"
  echo DESIRED GROUP    = "${GIT_GROUP}"
  echo SCRIPT VERBOSITY = "${VERBOSITY}"
fi

if [ $VERBOSITY -gt 0 ]; then
  echo "Converting $GIT_DIR to a shared repository..."
fi

# set recursive ownership
if [ $VERBOSITY -gt 0 ]; then
  echo "Setting repository ownership..."
fi
if [ "$DRY_RUN" = "true" ]; then
  echo "chown -R $VERBOSE $GIT_USER:$GIT_GROUP $GIT_DIR"
else
  chown -R $VERBOSE $GIT_USER:$GIT_GROUP $GIT_DIR
fi

# set shared repository
if [ "$NO_SHARED" = "true" ]; then
  if [ $VERBOSITY -gt 0 ]; then
    echo "Skipped setting core.sharedRepository to group"
  fi
else
  if [ $VERBOSITY -gt 0 ]; then
    echo "Setting core.sharedRepository to group..."
  fi
  if [ "$DRY_RUN" = "true" ]; then
    echo "git config core.sharedRepository group"
  else
    git config core.sharedRepository group
  fi
fi

# set file permissions
if [ $VERBOSITY -gt 0 ]; then
  echo "Setting file permissions..."
fi
if [ "$DRY_RUN" = "true" ]; then
  echo "find $GIT_DIR -type f | xargs chmod $VERBOSE $FILE_MASK"
  echo "find $GIT_DIR -type d | xargs chmod $VERBOSE $DIR_MASK"
  echo "find $GIT_DIR -type d | xargs chmod $VERBOSE g+s"
else
  find $GIT_DIR -type f | xargs chmod $VERBOSE $FILE_MASK
  find $GIT_DIR -type d | xargs chmod $VERBOSE $DIR_MASK
  find $GIT_DIR -type d | xargs chmod $VERBOSE g+s
fi

if [ $VERBOSITY -gt 0 ]; then
  echo "Finished."
fi

exit_script 0
