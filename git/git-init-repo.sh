#!/bin/bash
# this script inits a new git repository at the specified location
# rwb[at]0x19e[dot]net

# check if git command exists
hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

# default settings
GIT_USER=$(whoami)
GIT_GROUP=$(whoami)

SHARED_FILE_MASK=664
SHARED_DIR_MASK=775

VERBOSITY=0

pushd()
{
  command pushd "$@" > /dev/null
}

popd()
{
  if [ $(dirs -p -v | wc -l) -gt 1 ]; then
    command popd "$@" > /dev/null
  fi
}

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

    This script creates a new bare Git repository.

    SYNTAX
            SCRIPT_NAME [OPTIONS] ARGUMENTS

    ARGUMENTS

     repository              The location where a new repository should
                             should be created. If --script-relative is
                             specified then the location of the script
                             will be appended to the front.

    OPTIONS

     -u, --user <value>      The user that should own the repository.
     -g, --group <value>     The group that should own the repository.
     -h, --set-head <value>  Set the head branch for the repository.

     -t,--template <value>   Directory containing templates.
     -r,--script-relative    The specified path is relative to the location
                             of this script.

     -s,--make-shared        Configure the repository for sharing.
     -n,--allow-non-ff       Allow non-fast-forward push from the client.
     --dry-run               Print commands without making any changes.

     -v, --verbose           Make the script more verbose.
     -h, --help              Prints this usage.

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

test_owner_permission() {
  # test if root is required to set desired ownership
  local desired_user="$1"
  local desired_group="$2"
  local target_path="$3"
  local needs_root="false"

  # default values if arguments not specified
  if [ -z "$desired_used" ]; then
    desired_user="$GIT_USER"
  fi
  if [ -z "$desired_group" ]; then
    desired_group="$GIT_GROUP"
  fi

  # todo: this should resolve down to the first existing path
  if [ -n "$target_path" ]; then
    while [ ! -d "$target_path" ]; do
      # resolve the part of $target_path that already exists
      target_path=$(dirname "${target_path}")
    done
    if [ $VERBOSITY -gt 1 ]; then
      echo "Parent folder resolved to $target_path, checking permissions...."
    fi
  fi

  # check if the current user is the desired user
  if [ $VERBOSITY -gt 1 ]; then
    echo "Testing user permission..."
  fi
  if [ "$(whoami)" != "$desired_user" ]; then
    if [ $VERBOSITY -gt 1 ]; then
      echo "WARNING: $desired_user is not us; root permission required."
    fi
    needs_root="true"
  fi

  # check if the current user belongs to the specified grop
  if [ $VERBOSITY -gt 1 ]; then
    echo "Testing group permission..."
  fi
  if ! groups $(whoami) | grep "\b$desired_group\b" &>/dev/null; then
    if [ $VERBOSITY -gt 1 ]; then
      echo "WARNING: $(whoami) not a member of $desired_group; root permission required."
    fi
    needs_root="true"
  fi

  # test path permissions
  if [ "$needs_root" != "true" ] && [ -n "$target_path" ] && [ -d "$target_path" ]; then
    STAT_INFO=( $(stat -c "0%a %G %U" -L $target_path) )
    local path_perm=${STAT_INFO[0]}
    local path_group=${STAT_INFO[1]}
    local path_user=${STAT_INFO[2]}

    if [ $VERBOSITY -gt 1 ]; then
      echo "INFO: Octal permissions for $target_path : $path_perm"
    fi

    if ((($path_perm & 0020) != 0)); then
      # Some group has write access.
      # test path group permission
      if [ $VERBOSITY -gt 1 ]; then
        echo "INFO: Checking if we are a member of path group $path_group ..."
      fi
      if ! groups $(whoami) | grep "\b$path_group\b" &>/dev/null; then
        if [ $VERBOSITY -gt 1 ]; then
          echo "WARNING: $(whoami) not a member of $path_group; root permission required."
        fi
        needs_root="true"
      fi
    elif ((($path_perm & 0200) != 0)); then
      # The owner has write access.
      # Does the user own the file?
      if [ $VERBOSITY -gt 1 ]; then
        echo "INFO: Checking if we own target path ..."
      fi
      if [ "$(whoami)" != "$path_user" ]; then
        if [ $VERBOSITY -gt 1 ]; then
          echo "WARNING: $path_user is not us; root permission required."
        fi
        needs_root="true"
      fi
    fi
  fi

  if [ "$needs_root" == "true" ]; then
    # check if superuser
    if [[ $EUID -ne 0 ]]; then
      exit_script 1 "This script must be run as root to set the desired permissions."
    fi
  fi
}

VERBOSE=""
GIT_VERBOSE="-q"

check_verbose()
{
  if [ $VERBOSITY -gt 0 ]; then
    GIT_VERBOSE=""
  fi
  if [ $VERBOSITY -gt 1 ]; then
    VERBOSE="-v"
  fi
}

GIT_DIR=""
GIT_HEAD=""
GIT_TEMPLATE=""
GIT_SHARED=""
DRY_RUN="false"
MAKE_SHARED="false"
ALLOW_NONFF="false"
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
    -h|--set-head)
      test_arg "$1" "$2"
      shift
      GIT_HEAD="$1"
      shift
    ;;
    -r|--script-relative)
      SCRIPT_RELATIVE="true"
      shift
    ;;
    -s|--make-shared)
      MAKE_SHARED="true"
      GIT_SHARED="--shared"
      shift
    ;;
    -n|--allow-non-ff)
      ALLOW_NONFF="true"
      shift
    ;;
    --dry-run)
      DRY_RUN="true"
      shift
    ;;
    -t|--template)
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
      test_arg "$1"
      if [ -n "$GIT_DIR" ]; then
        usage "Repository location can only be specified once."
      fi
      GIT_DIR="$1"
      shift
    ;;
  esac
done

# make sure a path was specified
if [ -z "$GIT_DIR" ]; then
  usage
fi

GIT_EXTRA_ARGS="$GIT_SHARED $GIT_VERBOSE $GIT_TEMPLATE"

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
  printf "%-16s = %s\n" "GIT REPOSITORY" ${GIT_DIR}
  printf "%-16s = %s\n" "DESIRED OWNER" ${GIT_USER}
  printf "%-16s = %s\n" "DESIRED GROUP" ${GIT_GROUP}
  printf "%-16s = %s\n" "GIT EXTRA ARGS" ${GIT_EXTRA_ARGS}
  printf "%-16s = %s\n" "SCRIPT VERBOSITY" ${VERBOSITY}
fi

# perform final checks
test_path "$GIT_DIR"
test_user_arg "$GIT_USER"
test_group_arg "$GIT_GROUP"

# ensure we have enough privileges to set permissions
if [ "$DRY_RUN" = "false" ]; then
  test_owner_permission "$GIT_USER" "$GIT_GROUP" "$GIT_DIR"
else
  echo >&2 "WARNING: Skipping permission checks (--dry-run)"
fi

if [ $VERBOSITY -gt 0 ]; then
  echo "Creating Git repository at $GIT_DIR ..."
fi

if [ "$DRY_RUN" = "true" ]; then
  # print out commands without running anything
  echo mkdir $VERBOSE -p "$GIT_DIR"
  echo git init --bare $GIT_EXTRA_ARGS "$GIT_DIR"
else
  # create directory
  mkdir $VERBOSE -p "$GIT_DIR"

  # init the repository
  if ! git init --bare $GIT_EXTRA_ARGS "$GIT_DIR"; then
    exit_script 1 "Failed to init Git repository."
  fi
fi

if [ -n "$GIT_HEAD" ]; then
  if [ $VERBOSITY -gt 0 ]; then
    echo "Setting head to $GIT_HEAD ..."
  fi
  pushd "$GIT_DIR"
  git symbolic-ref HEAD refs/heads/$GIT_HEAD
  popd
fi

if [ "$ALLOW_NONFF" = "true" ]; then
  if [ $VERBOSITY -gt 0 ]; then
    echo "Configure to enable non-fast-forward pushes ..."
  fi
  pushd "$GIT_DIR"
  git config receive.denynonfastforwards false
  popd
fi

if [ "$DRY_RUN" = "true" ]; then
  echo chown $VERBOSE -R $GIT_USER:$GIT_GROUP "$GIT_DIR"
else
  chown $VERBOSE -R $GIT_USER:$GIT_GROUP "$GIT_DIR"
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
