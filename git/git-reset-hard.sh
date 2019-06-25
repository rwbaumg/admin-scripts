#!/bin/bash
# Reset the current branch to match origin remote

UPSTREAM_REMOTE="origin"

# TODO: Support input Git dir argument
GIT_DIR=$(readlink -m ".")

if [ -z "${UPSTREAM_REMOTE}" ]; then
  echo >&2 "No upstream remote is configured."
  exit 1
fi

if [ "$(dirname "$0")" = "$GIT_DIR" ]; then
  echo >&2 "This script must be run from within a valid Git repository."
  exit 1
fi

if ! git -C "$GIT_DIR" rev-parse; then
  echo >&2 "Directory does not appear to be a valid Git repository: $GIT_DIR"
  exit 1
fi

# BRANCH_NAME=$(git branch | grep "\*" | cut -d ' ' -f2)
# if ! git ls-remote "$UPSTREAM_REMOTE" > /dev/null 2>&1; then
# if ! git ls-remote --heads "${UPSTREAM_REMOTE}" "${BRANCH_NAME}" | grep "${BRANCH_NAME}" >/dev/null; then

ORIGIN_RE=$(echo "${UPSTREAM_REMOTE}" | sed -e 's/\+/\\+/g' -e 's/\-/\\-/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g')
if ! git remote 2>&1 | grep -P "^$ORIGIN_RE"; then
  echo >&2 "Working copy doesn't have a remote named '$UPSTREAM_REMOTE'. Aborting."
  exit 1
fi

echo "Fetching from remote '${UPSTREAM_REMOTE}' ..."
if ! git fetch "${UPSTREAM_REMOTE}"; then
  echo >&2 "Failed to pull from remote '${UPSTREAM_REMOTE}'."
  exit 1
fi

# Get branch name and make sure it exists on the remote
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
BRANCH_RE=$(echo "${BRANCH_NAME}" | sed -e 's/\+/\\+/g' -e 's/\-/\\-/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g')
if ! git branch -r 2>&1 | grep -P "(\s+)?${ORIGIN_RE}\/${BRANCH_RE}\$"; then
  echo >&2 "ERROR: Could not find remote branch: '$UPSTREAM_REMOTE/$BRANCH_NAME'. Aborting."
  exit 1
fi

echo "Attempting a hard reset for branch '${BRANCH_NAME}' in Git directory '$GIT_DIR' ..."

if ! git reset --hard "${UPSTREAM_REMOTE}/${BRANCH_NAME}"; then
  echo >&2 "ERROR: Failed to reset branch to '${UPSTREAM_REMOTE}/${BRANCH_NAME}'"
  exit 1
fi

#if ! git clean -fd; then
#  echo >&2 "ERROR: Failed to clean working directory."
#  exit 1
#fi

echo "Finished."
exit 0
