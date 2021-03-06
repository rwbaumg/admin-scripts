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
  command pushd "$*" > /dev/null
}

popd()
{
  if [ "$(dirs -p -v | wc -l)" -gt 1 ]; then
    command popd "$*" > /dev/null
  fi
}

exit_script()
{
  # Default exit code is 1
  local exit_code=1
  local re

  re='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'
  if echo "$1" | grep -qE "$re"; then
    exit_code=$1
    shift
  fi

  re='[[:alnum:]]'
  if echo "$*" | grep -iqE "$re"; then
    if [ "$exit_code" -eq 0 ]; then
      echo "INFO: $*"
    else
      echo "ERROR: $*" 1>&2
    fi
  fi

  # Print 'aborting' string if exit code is not 0
  [ "$exit_code" -ne 0 ] && echo "Aborting script..."

  # pop back to start directory
  popd "$@"

  exit "$exit_code"
}

usage()
{
    # Prints out usage and exit.
    sed -e "s/^    //" -e "s|SCRIPT_NAME|$(basename "$0")|" << EOF
    USAGE

    Rewrites current Git repository history to update user details.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS

     --old-name  <value>    The name of the user to rewrite.
     --old-email <value>    The e-mail of the user to rewrite.
     --new-name  <value>    The new/corrected name for the user.
     --new-email <value>    The new/corrected e-mail for the user.

     --dry-run              Do not make any changes.

     -f, --force            Force re-write.
     -v, --verbose          Make the script more verbose.
     -h, --help             Prints this usage.

EOF

    exit_script "$@"
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

  test_arg "$arg"

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

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi
}

test_email_arg()
{
  # test user argument
  local arg="$1"
  local argv="$2"

  test_arg "$arg" "$argv"

  if [ -z "$argv" ]; then
    argv="$arg"
  fi

  # regex borrowed from https://emailregex.com/
  re='(?:[a-z0-9!#$%&'"'"'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"'"'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'
  if ! echo "$argv" | grep -Poq "$re"; then
    usage "Invalid e-mail address: ${argv}"
  fi
}

FORCE=""
DRY_RUN=0
VERBOSITY=0
#VERBOSE=""
#check_verbose()
#{
#  if [ $VERBOSITY -gt 1 ]; then
#    VERBOSE="-v"
#  fi
#}

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
    --dry-run)
      ((VERBOSITY++))
      DRY_RUN=1
      shift
    ;;
    -f|--force)
      FORCE="-f"
      shift
    ;;
    -v|--verbose)
      ((VERBOSITY++))
      #check_verbose
      shift
    ;;
    -vv)
      ((VERBOSITY++))
      ((VERBOSITY++))
      #check_verbose
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

if ! git -C "$(dirname "$0")" rev-parse; then
  usage "Directory does not appear to be a valid Git repository: $DIR"
fi

if [ ! -d ".git" ]; then
  usage "This script must be run from the top-level of the repository."
fi

#if [ -z "$OLD_NAME" ]; then
#  usage "Must specify previous name with --old-name."
#else
if [ -n "$OLD_NAME" ]; then
  if [ -z "$CORRECT_NAME" ]; then
    usage "Must specify new/corrected name with --new-name."
  fi
elif [ -n "$CORRECT_NAME" ]; then
  usage "Must specify previous name with --old-name."
fi
#if [ -z "$OLD_EMAIL" ]; then
#  usage "Must specify previous email with --old-email"
#else
if [ -n "$OLD_EMAIL" ]; then
  if [ -z "$CORRECT_EMAIL" ]; then
    usage "Must specify new/corrected email with --new-email."
  fi
elif [ -n "$CORRECT_EMAIL"  ]; then
  usage "Must specify previous email with --old-email"
fi

if [ $VERBOSITY -gt 0 ]; then
echo "Using command:"
# shellcheck disable=2016
echo git filter-branch $FORCE --env-filter '
	if [ -n "'"$OLD_NAME"'" ] && [ -n "'"$CORRECT_NAME"'" ]; then
		# correct committer name
		if test "${GIT_COMMITTER_NAME}" = "'"${OLD_NAME}"'"; then
			export GIT_COMMITTER_NAME="'"${CORRECT_NAME}"'"
		fi

		# correct author name
		if test "${GIT_AUTHOR_NAME}" = "'"$OLD_NAME"'"; then
			export GIT_AUTHOR_NAME="'"$CORRECT_NAME"'"
		fi
	fi
	if [ -n "'"$OLD_EMAIL"'" ] && [ -n "'"$CORRECT_EMAIL"'" ]; then
                # correct committer e-mail
                if test "$GIT_COMMITTER_EMAIL" = "'"$OLD_EMAIL"'"; then
                        export GIT_COMMITTER_EMAIL="'"$CORRECT_EMAIL"'"
                fi

		# correct author e-mail
		if test "$GIT_AUTHOR_EMAIL" = "'"$OLD_EMAIL"'"; then
			export GIT_AUTHOR_EMAIL="'"$CORRECT_EMAIL"'"
		fi
	fi
' --tag-name-filter cat -- --branches --tags
fi

if [ "$DRY_RUN" == 1 ]; then
  exit 0
fi

########################################

echo "Running rewrite ..."

# rewrite author info
# shellcheck disable=2016
if ! git filter-branch $FORCE --env-filter '
	if [ -n "'"$OLD_NAME"'" ] && [ -n "'"$CORRECT_NAME"'" ]; then
		# correct committer name
		if test "${GIT_COMMITTER_NAME}" = "'"${OLD_NAME}"'"; then
			export GIT_COMMITTER_NAME="'"${CORRECT_NAME}"'"
		fi

		# correct author name
		if test "${GIT_AUTHOR_NAME}" = "'"$OLD_NAME"'"; then
			export GIT_AUTHOR_NAME="'"$CORRECT_NAME"'"
		fi
	fi
	if [ -n "'"$OLD_EMAIL"'" ] && [ -n "'"$CORRECT_EMAIL"'" ]; then
                # correct committer e-mail
                if test "$GIT_COMMITTER_EMAIL" = "'"$OLD_EMAIL"'"; then
                        export GIT_COMMITTER_EMAIL="'"$CORRECT_EMAIL"'"
                fi

		# correct author e-mail
		if test "$GIT_AUTHOR_EMAIL" = "'"$OLD_EMAIL"'"; then
			export GIT_AUTHOR_EMAIL="'"$CORRECT_EMAIL"'"
		fi
	fi
' --tag-name-filter cat -- --branches --tags; then
        echo >&2 "ERROR: Rewrite failed."
        exit 1
fi

exit 0
