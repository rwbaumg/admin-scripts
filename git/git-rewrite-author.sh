#!/bin/bash
#
# [ 0x19e Networks ]
#
# Rewrites Git history to correct author information
#
# To push updates after a rewrite, use:
#  git push --force --tags origin 'refs/heads/*'
#
# Note that this is considered bad practice for published branches.
#
# Author: Robert W. Baumgartner <rwb@0x19e.net>
# Modified from GitHub script:
#   https://help.github.com/articles/changing-author-info/
#

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

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
  if echo "$1" | grep -qE "$re"; then
    exit_code=$1
    shift
  fi

  re='[[:alnum:]]'
  if echo "$@" | grep -iqE "$re"; then
    if [ $exit_code -eq 0 ]; then
      echo "INFO: $*"
    else
      echo "ERROR: $*" 1>&2
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
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename $0)|" << EOF
    USAGE

    Rewrites current Git repository history to update user details.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS

     --old-name  <value>    The name of the user to rewrite.
     --old-email <value>    The e-mail of the user to rewrite.
     --new-name  <value>    The new/corrected name for the user.
     --new-email <value>    The new/corrected e-mail for the user.

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
    if echo "$arg" | grep -qE '^-'; then
      usage "Null argument supplied for option $arg"
    fi
  fi

  if echo "$argv" | grep -qE '^-'; then
    usage "Argument for option $arg cannot start with '-'"
  fi
}

test_git_path()
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
}

test_email_arg()
{
  # test user argument
  local arg="$1"
  local argv="$2"

  test_arg $arg $argv

  if [ -z "$argv" ]; then
    argv="$arg"
  fi
}

VERBOSE=""

check_verbose()
{
  if [ $VERBOSITY -gt 1 ]; then
    VERBOSE="-v"
  fi
}

export OLD_NAME=""
export OLD_EMAIL=""
export CORRECT_NAME=""
export CORRECT_EMAIL=""

# process arguments
[ $# -gt 0 ] || usage
while [ $# -gt 0 ]; do
  case "$1" in
    --old-name)
      test_user_arg "$1" "$2"
      shift
      export OLD_NAME="$1"
      shift
    ;;
    --old-email)
      test_email_arg "$1" "$2"
      shift
      export OLD_EMAIL="$1"
      shift
    ;;
    --new-name)
      test_user_arg "$1" "$2"
      shift
      export CORRECT_NAME="$1"
      shift
    ;;
    --new-email)
      test_email_arg "$1" "$2"
      shift
      export CORRECT_EMAIL="$1"
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
      usage "Unknown option."
      shift
    ;;
  esac
done

if ! $(git -C "$(dirname $0)" rev-parse); then
  usage "Directory does not appear to be a valid Git repository: $DIR"
  #echo >&2 "Directory does not appear to be a valid Git repository: $DIR"
  #exit 1
fi

if [ ! -d ".git" ]; then
  usage "This script must be run from the top-level of the repository."
fi

if [ -z "$OLD_NAME" ]; then
  usage "Must specify previous name with --old-name."
fi
if [ -z "$CORRECT_NAME" ]; then
  usage "Must specify new/corrected name with --new-name."
fi
#if [ -z "$OLD_EMAIL" ]; then
#  usage "Must specify previou email with --old-email"
#fi
#if [ "$CORRECT_EMAIL" ]; then
#  usage "Must specify new/corrected email with --new-email."
#fi

# rewrite author info
git filter-branch --env-filter '
	if [ -n "$OLD_NAME" ]; then
		# correct committer name
		if [ "$GIT_COMMITTER_NAME" = "$OLD_NAME" ]; then
			export GIT_COMMITTER_NAME="$CORRECT_NAME"
			export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
		fi

		# correct author name
		if [ "$GIT_AUTHOR_NAME" = "$OLD_NAME" ]; then
			export GIT_AUTHOR_NAME="$CORRECT_NAME"
			export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
		fi
	fi

	if [ -n "$OLD_EMAIL" ]; then
		# correct committer e-mail
		if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]; then
			export GIT_COMMITTER_NAME="$CORRECT_NAME"
			export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
		fi

		# correct author e-mail
		if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]; then
			export GIT_AUTHOR_NAME="$CORRECT_NAME"
			export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
		fi
	fi
' --tag-name-filter cat -- --branches --tags

exit 0
