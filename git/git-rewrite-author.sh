#!/bin/bash
# Rewrites Git history to correct author information
# Note that this is considered bad practice for published branches.
# Modified from GitHub script:
#   https://help.github.com/articles/changing-author-info/
#
# TODO: Add argument support

OLD_NAME="rwb"
OLD_EMAIL="rwb@0x19e.net"
CORRECT_NAME="Robert W. Baumgartner"
CORRECT_EMAIL="rwb@0x19e.net"

# rewrite author info
git filter-branch --env-filter '
	if [ ! -z "$OLD_NAME" ]; then
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

	if [ ! -z "$OLD_EMAIL" ]; then
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
' --tag-name-filter cat -f -- --all --tags
