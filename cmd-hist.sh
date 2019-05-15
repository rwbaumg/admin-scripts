#!/bin/bash
# Allows searching command history for the current user
# Note: The leading index can be stripped from 'history'
# output using 'awk', e.g.:
#  history | awk '{first = $1; $1 = ""; print $0, first; }'

# Set the number of commands to display
TOP_COUNT=20

# Parse command history
HISTORY=$(cat ~/.bash_history | grep "$1")
TOTAL=$(echo "$HISTORY" | wc -l)
UNIQUE=$(echo "$HISTORY" | sort | uniq -c)
TOP_CMD=$(echo "$UNIQUE" | sort -rh | head -${TOP_COUNT})
COUNT=$(echo "$UNIQUE" | wc -l)

# Display results
echo "Command History"
echo "==============="
if [ -n "$1" ]; then
echo "Applied command filter (grep): $1"
fi
echo "Found $COUNT unique commands out of $TOTAL BASH history entries for $USER."
echo "Top $TOP_COUNT commands:"
echo "$TOP_CMD"

exit 0
