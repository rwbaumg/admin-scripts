#!/bin/bash
# Lists unversioned and ignored files in a Git repository

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

# check that we're actually in a repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo >&2 "Current directory is not a git repository. Aborting."
  exit 1
fi

echo >&2 "Unversioned / ignored files:"

git clean -dnx | cut -c 14-

exit 0
