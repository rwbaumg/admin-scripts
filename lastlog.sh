#!/bin/bash
# List the logs last written to

LOGGING_PATH=/var/log
RESULT_COUNT=12

ls -lt ${LOGGING_PATH} | head -n${RESULT_COUNT}

exit 0
