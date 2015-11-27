#!/bin/bash
# script to push all git refs from origin to the specified remote
# rwb[at]0x19e[dot]net

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

# default remotes
SOURCE_REMOTE="origin"
TARGET_REMOTE=""

# array of refs. to exclude from mirror
EXCLUDE_REFS=("HEAD")

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

    Push Git refs to another remote.

    This script allows mirroring a Git repository's remote branch
    and tag references to another remote.

    SYNTAX
            SCRIPT_NAME [OPTIONS]

    OPTIONS

     -o, --origin <value>   The name of the remote to push refs from (default: origin)
     -r, --remote <value>   The name of the remote to push refs to (default: 0x19e)
     -i, --ignore <value>   Ignore the specified branch reference (HEAD is always ignored).
     -f, --force            Pass the --force flag to the Git command to bypass reference checks.

     -v, --verbose          Make the script more verbose.

     --no-tags              Don't process Git tag references (only branches)
     --dry-run              Do everything except actually send the updates.
     --convert-svn-tags     Convert SVN tags to Git tags before pushing to the specified remote.
     --prune                Deletes all stale remote-tracking branches under the remote.

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
GIT_FORCE=""
GIT_PRUNE=""
SKIP_TAGS="false"
CONVERT_SVN_TAGS="false"

while [ $# -gt 0 ]; do
case "$1" in
  -o|--origin)
    test_arg "$1" "$2"
    shift
    SOURCE_REMOTE="$1"
    shift
    ;;
  -r|--remote)
    test_arg "$1" "$2"
    shift
    TARGET_REMOTE="$1"
    shift
    ;;
  -v|--verbose)
    GIT_VERBOSE="-v"
    ((VERBOSITY++))
    shift
    ;;
  -f|--force)
    GIT_FORCE="--force"
    shift
    ;;
  -i|--ignore)
    test_arg "$1" "$2"
    shift
    EXCLUDE_REFS+=("$1")
    shift
    ;;
  --dry-run)
    GIT_DRY_RUN="--dry-run"
    shift
    ;;
  --no-tags)
    SKIP_TAGS="true"
    shift
    ;;
  --convert-svn-tags)
    CONVERT_SVN_TAGS="true"
    shift
    ;;
  --prune)
    GIT_PRUNE="--prune"
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

if [ -z "$TARGET_REMOTE" ]; then
  usage "No remote specified for target."
fi
if [ -z "$SOURCE_REMOTE" ]; then
  usage "No remote specified for source."
fi

# combine git flags
GIT_EXTRA_ARGS="$GIT_VERBOSE $GIT_FORCE $GIT_DRY_RUN"
EXCLUDE_REFS_KEY=$(echo ${EXCLUDE_REFS[@]}|tr " " "|")

# print options
if [ $VERBOSITY -gt 1 ]; then
  echo ORIGIN REMOTE = "${SOURCE_REMOTE}"
  echo TARGET REMOTE = "${TARGET_REMOTE}"
  echo EXCLUDED REFS = "${EXCLUDE_REFS_KEY}"
  echo GIT ARGUMENTS = "${GIT_EXTRA_ARGS}"
fi

# check that we're actually in a repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo >&2 "Current directory is not a git repository. Aborting."
  exit 1
fi

# check remotes
if ! git ls-remote $SOURCE_REMOTE > /dev/null 2>&1; then
  echo >&2 "Working copy doesn't have a remote named '$SOURCE_REMOTE'. Aborting."
  exit 1
fi
if ! git ls-remote $TARGET_REMOTE > /dev/null 2>&1; then
  echo >&2 "Working copy doesn't have a remote named '$TARGET_REMOTE'. Aborting."
  exit 1
fi

# prepare ref list
GIT_REFS=$(git branch -r | grep "^..$SOURCE_REMOTE\/[a-zA-Z0-9\._-]*$" | sed -e 's/^..//' | grep -Ewv "$EXCLUDE_REFS_KEY")
GIT_SVN_TAGS=$(git branch -r | grep "^..$SOURCE_REMOTE\/tags\/[a-zA-Z0-9\._-]*$" | sed -e 's/^..//' | sed -e 's/^..tags\///')

# print processed refs
if [ $VERBOSITY -gt 1 ]; then
  echo "INFO: The following branches were found in $SOURCE_REMOTE: $(echo ${GIT_REFS[@]}|tr " " "|")"
fi
if [ $VERBOSITY -gt 1 ]; then
  echo "INFO: The following SVN tags were found in $SOURCE_REMOTE: $(echo ${GIT_SVN_TAGS[@]}|tr " " "|")"
fi

# push all branches (excluding filtered)
if [ $VERBOSITY -gt 0 ]; then
  echo "Pushing branches to $TARGET_REMOTE ..."
fi
for remote_ref in $GIT_REFS; do
  remote_name=$(echo $remote_ref | sed -e "s/$SOURCE_REMOTE\///")

  if [ $VERBOSITY -gt 1 ]; then
    echo "Pushing $remote_name -> $TARGET_REMOTE ..."
  fi

  git push $GIT_EXTRA_ARGS $TARGET_REMOTE $remote_ref:refs/heads/$remote_name
done

if [ "$CONVERT_SVN_TAGS" = "true" ] && ! [ -d .git/svn  ]; then
  echo >&2 "WARNING: Can't convert SVN tags for non-SVN working copy."
  CONVERT_SVN_TAGS="false"
fi

if [ "$CONVERT_SVN_TAGS" = "true" ] && [ -n "$GIT_SVN_TAGS" ]; then
  if [ $VERBOSITY -gt 0 ]; then
    echo "Converting SVN tags to Git tags ..."
  fi
  for svn_tag in $GIT_SVN_TAGS; do
    # get svn tag name
    tag_name=$(echo $svn_tag | sed -e "s/$SOURCE_REMOTE\/tags\///")

    if [ $VERBOSITY -gt 1 ]; then
      echo "Processing SVN tag: $tag_name ($svn_tag) ..."
    fi

    if [ -z "$GIT_DRY_RUN" ]; then
      if git tag --list --contains "$tag_name" > /dev/null 2>&1; then
        if [ $VERBOSITY -gt 0 ]; then
          echo "Tag already exists: $tag_name"
        fi
      else
        # convert the svn branch to a git tag
        # note: git-tag doesn't support --verbose or --dry-run
        GIT_AUTHOR_NAME="$(git log -1 --pretty=format:%an $svn_tag)" \
        GIT_AUTHOR_EMAIL="$(git log -1 --pretty=format:%ae $svn_tag)" \
        GIT_AUTHOR_DATE="$(git log -1 --pretty=format:%ad $svn_tag)" \
        GIT_COMMITTER_NAME="$(git log -1 --pretty=format:%cn $svn_tag)" \
        GIT_COMMITTER_EMAIL="$(git log -1 --pretty=format:%ce $svn_tag)" \
        GIT_COMMITTER_DATE="$(git log -1 --pretty=format:%cd $svn_tag)" \
        git tag -a -m "$(git log -1 --pretty=format:%s%n%b $svn_tag)" $tag_name refs/remotes/origin/tags/$tag_name
      fi
    else
      # this is a dry run, just print a message if verbose enough
      if [ $VERBOSITY -gt 0 ]; then
        echo "Create tag $tag_name: $svn_tag -> refs/tags/$tag_name"
      fi
    fi
  done
fi

# push tags
if [ "$SKIP_TAGS" != "true" ] && git show-ref --tags > /dev/null 2>&1; then
  if [ $VERBOSITY -gt 0 ]; then
    echo "Pushing tags to $TARGET_REMOTE ..."
  fi

  # push all (tags without any filtering)
  git push $GIT_EXTRA_ARGS $GIT_PRUNE $TARGET_REMOTE +refs/tags/*:refs/tags/*

  # todo: could filter through tags if we wanted to...
else
  if [ $VERBOSITY -gt 0 ]; then
    echo "Skipped pushing tag references."
  fi
fi

if [ $VERBOSITY -gt 0 ]; then
  echo "Finished pushing references to $TARGET_REMOTE."
fi

if [ -n "$GIT_PRUNE" ]; then
  if [ $VERBOSITY -gt 0 ]; then
    echo "Pruning $TARGET_REMOTE ..."
  fi

  # prune remote refs
  git remote prune $TARGET_REMOTE $GIT_DRY_RUN
fi

exit_script 0
