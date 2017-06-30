#!/bin/sh
# Rewrites Git history to correct author information
# Note that this is considered bad practice for published branches.
# Modified from GitHub script:
#   https://help.github.com/articles/changing-author-info/


git filter-branch --env-filter '
	OLD_NAME="rwb"
	OLD_EMAIL="rwb@0x19e.net"
	CORRECT_NAME="Robert W. Baumgartner"
	CORRECT_EMAIL="rwb@0x19e.net"

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
' --tag-name-filter cat -f -- --all
# ' --tag-name-filter cat -- --branches --tags
