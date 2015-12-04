#!/bin/bash
# DANGER - THIS SCRIPT IS UNSAFE!
# Make sure you enter a valid (new) path for the repository
# relative to /srv/git/

# check if git command exists
hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

# default settings
GIT_USER=$(whoami)
GIT_GROUP=$(whoami)

SHARED_FILE_MASK=664
SHARED_DIR_MASK=775

VERBOSITY=0

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }
hash sed 2>/dev/null || { echo >&2 "You need to install sed. Aborting."; exit 1; }
hash grep 2>/dev/null || { echo >&2 "You need to install grep. Aborting."; exit 1; }

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

    This script creates a new bare Git repository.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     repository            The bare Git repository to make shared.

    OPTIONS

     -u, --user <value>    The user that should own the repository.
     -g, --group <value>   The group that should own the repository.

     --template <value>    Directory containing templates.
     --script-relative     The specified path is relative to the location
                           of this script.

     --make-shared         Configure the repository for sharing.
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

  if [ -e "$arg" ]; then
    usage "Specified directory already exists."
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

check_root() {
  # check if superuser
  if [[ $EUID -ne 0 ]]; then
    exit_script 1 "This script must be run as root."
  fi
}

GIT_VERBOSE="-q"

check_verbose()
{
  if [ $VERBOSITY -gt 0 ]; then
    GIT_VERBOSE=""
  fi
}

GIT_DIR=""
GIT_TEMPLATE=""
GIT_SHARED=""
DRY_RUN="false"
MAKE_SHARED="false"
SCRIPT_RELATIVE="false"

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
    --script-relative)
      SCRIPT_RELATIVE="true"
      shift
    ;;
    --make-shared)
      MAKE_SHARED="true"
      GIT_SHARED="--shared"
      shift
    ;;
    --dry-run)
      DRY_RUN="true"
      shift
    ;;
    --template)
      test_arg "$1" "$2"
      shift
      GIT_TEMPLATE="--template $1"
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
      # test_path "$1"
      GIT_DIR="$1"
      # GIT_DIR=$(readlink -m "$1")
      shift
    ;;
  esac
done

GIT_EXTRA_ARGS="$GIT_TEMPLATE $GIT_SHARED"

# check verbosity setting
check_verbose

if [ "$SCRIPT_RELATIVE" = "true" ]; then
  if [ $VERBOSITY -gt 1 ]; then
    echo "Using relative path..."
  fi
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    # if $SOURCE was a relative symlink, we need to resolve it relative to the path where
    # the symlink file was located
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  GIT_ROOT="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  if [ $VERBOSITY -gt 1 ]; then
    echo "Resolved script directory: $GIT_ROOT"
  fi
  GIT_DIR=$(readlink -m "$GIT_ROOT/$GIT_DIR")
fi

# print options
if [ $VERBOSITY -gt 1 ]; then
  echo GIT REPOSITORY   = "${GIT_DIR}"
  echo DESIRED OWNER    = "${GIT_USER}"
  echo DESIRED GROUP    = "${GIT_GROUP}"
  echo GIT EXTRA ARGS   = "${GIT_EXTRA_ARGS}"
  echo SCRIPT VERBOSITY = "${VERBOSITY}"
fi

# perform final checks
test_path "$GIT_DIR"
test_user_arg "$GIT_USER"
test_group_arg "$GIT_GROUP"

# ensure the script is run as root, otherwise we may not have
# sufficient permissions to reconfigure the repository
#if [ "$DRY_RUN" = "false" ]; then
#  check_root
#fi

if [ $VERBOSITY -gt 0 ]; then
  echo "Creating Git repository at $GIT_DIR ..."
fi

if [ "$DRY_RUN" = "true" ]; then
  echo mkdir -p "$GIT_DIR"
  echo git init --bare $GIT_EXTRA_ARGS "$GIT_DIR"
  echo chown -R $GIT_USER:$GIT_GROUP "$GIT_DIR"
else
  mkdir -p "$GIT_DIR"
  if ! git init --bare $GIT_EXTRA_ARGS "$GIT_DIR"; then
    exit_script 1 "Failed to init Git repository."
  fi

  chown -R $GIT_USER:$GIT_GROUP "$GIT_DIR"
fi

# set file permissions
if [ "$MAKE_SHARED" = "true" ]; then
  if [ $VERBOSITY -gt 0 ]; then
    echo "Setting file permissions for shared repository..."
  fi
  if [ "$DRY_RUN" = "true" ]; then
    echo "find $GIT_DIR/ -type f | xargs chmod $VERBOSE $SHARED_FILE_MASK"
    echo "find $GIT_DIR/ -type d | xargs chmod $VERBOSE $SHARED_DIR_MASK"
    echo "find $GIT_DIR/ -type d | xargs chmod $VERBOSE g+s"
  else
    find $GIT_DIR/ -type f | xargs chmod $VERBOSE $SHARED_FILE_MASK
    find $GIT_DIR/ -type d | xargs chmod $VERBOSE $SHARED_DIR_MASK
    find $GIT_DIR/ -type d | xargs chmod $VERBOSE g+s
  fi
fi

if [ $VERBOSITY -gt 0 ]; then
  echo "Finished."
fi

exit_script 0
